version: 0.2

env:
  parameter-store:
    BB_USER: "/app/bb_user"  
    BB_PASS: "/app/bb_app_pass"
    RELEASE_HOOK_URL: "/app/jira_release_hook"
    CONSUL_URL: "/infra/consul_url"
    CONSUL_HTTP_TOKEN: "/infra/${APP_NAME}-${ENV_TYPE}/consul_http_token"

phases:
  pre_build:
    commands:
      - yum install -y yum-utils
      - yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
      - yum -y install consul
      - yum -y install graphviz
      - export CONSUL_HTTP_ADDR=https://$CONSUL_URL
      - ECR_LOGIN=$(aws ecr get-login-password)
      - docker login --username AWS --password $ECR_LOGIN ${ECR_REPO_URL}
      - CODEBUILD_RESOLVED_SOURCE_VERSION="$CODEBUILD_RESOLVED_SOURCE_VERSION"
      - COMMENT="Pipeline has been done successfully."
      - PR_NUMBER=$(cat pr.txt)
      - SRC_CHANGED=$(cat src_changed.txt)
      - COMMIT_ID=$(cat commit_id.txt)
  build:
    commands:
      - |
         if [ "$SRC_CHANGED" = "true" ]; then
           DEPLOYED_TAG="${FROM_ENV}";
           MANIFEST=$(aws ecr batch-get-image --repository-name ${ECR_REPO_NAME} --image-ids imageTag=$DEPLOYED_TAG --output json | jq --raw-output '.images[0].imageManifest')
           aws ecr put-image --repository-name ${ECR_REPO_NAME} --image-tag "${ENV_NAME}" --image-manifest "$MANIFEST" || true
         fi
      - |
         if [ "$SRC_CHANGED" = "false" ]; then
           DEPLOYED_TAG="${ENV_NAME}";
           echo "Image already has $DEPLOYED_TAG tag."
         fi

  post_build:
    commands:
      - |
        REPORT_URL="https://console.aws.amazon.com/codesuite/codedeploy/applications/ecs-deploy-${APP_NAME}-${ENV_NAME}/deployment-groups/ecs-deploy-group-${APP_NAME}-${ENV_NAME}"
        URL="https://api.bitbucket.org/2.0/repositories/tolunaengineering/${APP_NAME}/commit/$COMMIT_ID/statuses/build/"
        curl --request POST --url $URL -u "$BB_USER:$BB_PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"key\":\"${APP_NAME} Deploy\",\"state\":\"SUCCESSFUL\",\"description\":\"Deployment to ${ENV_NAME} succeeded\",\"url\":\"$REPORT_URL\"}"    
      - |
        if [ "${ENV_NAME}" == "prod" ] && [ "${ENABLE_JIRA_AUTOMATION}" == "true" ] ; then 
          declare -a version=($(aws ecr describe-images --repository-name ${APP_NAME}-main --image-ids imageTag=${FROM_ENV} --query "imageDetails[0].imageTags[?Value==${FROM_ENV}]" --output text))
          export RELEASE_VERSION=$${version[1]}
          curl --request POST --url $RELEASE_HOOK_URL --header "Content-Type:application/json" --data "{\"data\": {\"releaseVersion\":\"$RELEASE_VERSION\"}}" || echo "No Jira to change"
        fi
      - |
        CURRENT_COLOR=$(consul kv get "infra/${APP_NAME}-${ENV_NAME}/current_color")
        IS_MANAGED_ENV=$(consul kv get "terraform/${APP_NAME}/app-env.json"| jq '."${ENV_NAME}".is_managed_env')
        DATADOG_LAMBDA_FUNCTION_ARN=$(aws lambda get-function --function-name "datadog-forwarder" --query 'Configuration.FunctionArn'  --output text)
        if [ "$DATADOG_LAMBDA_FUNCTION_ARN" ]; then
                echo "Datadog forwarder found $DATADOG_LAMBDA_FUNCTION_ARN"
                if [ "$IS_MANAGED_ENV" = "true" ];then
                        aws logs put-subscription-filter \
                                --destination-arn "$DATADOG_LAMBDA_FUNCTION_ARN" \
                                --log-group-name "${APP_NAME}-${ENV_NAME}-$CURRENT_COLOR" \
                                --filter-name "${APP_NAME}-${ENV_NAME}-$CURRENT_COLOR" \
                                --filter-pattern ""
                        echo "Managed Blue/Green infrastructure"
                        echo "Subscribing log group "${APP_NAME}-${ENV_NAME}-$CURRENT_COLOR" to "$DATADOG_LAMBDA_FUNCTION_ARN""
                else
                        aws logs put-subscription-filter \
                                --destination-arn "$DATADOG_LAMBDA_FUNCTION_ARN" \
                                --log-group-name "${APP_NAME}-${ENV_NAME}" \
                                --filter-name "${APP_NAME}-${ENV_NAME}" \
                                --filter-pattern ""
                        echo "Not managed development infrastructure"
                        echo "Subscribing log group "${APP_NAME}-${ENV_NAME}" to "$DATADOG_LAMBDA_FUNCTION_ARN""
                fi
        fi
      - |
        wget -qO- https://github.com/cycloidio/inframap/releases/download/v0.6.7/inframap-linux-amd64.tar.gz | tar xvz
        STATE_LAYERS=("app" "data" "shared")
        for s in "${STATE_LAYERS[@]}"; do
            if [ $s == "app" ]; then
                DATA_WORKSPACE=$(consul kv get "terraform/${APP_NAME}/app-env.json" | jq -r ".${ENV_NAME}.data_workspace")
                SHARED_LAYER=$(consul kv get "terraform/${APP_NAME}/app-env.json" | jq -r ".${ENV_NAME}.env_type")
            fi
            if [ $s == "data" ]; then
                ENV_NAME=$DATA_WORKSPACE
            elif [ $s == "shared" ]; then
                ENV_NAME="shared-"$SHARED_LAYER
            fi
            CHECK=$(consul kv get "terraform/${APP_NAME}/${s}/state-env:${ENV_NAME}" | jq -r '."current-hash"')
            if [ -z "$CHECK" ] || [ $CHECK == "null" ]; then
                STATE=$(consul kv get "terraform/${APP_NAME}/${s}/state-env:${ENV_NAME}").
                echo $STATE | jq | tee -a ${s}.tfstate >/dev/null
            else
                STATE=$(curl -sS "${CONSUL_HTTP_ADDR}/v1/kv/terraform/${APP_NAME}/${s}/state-env:${ENV_NAME}/?keys&token=${CONSUL_HTTP_TOKEN}")
                SAMPLE=($(echo $STATE | jq -r ".[]" | sed 's/[{|}]//g' | tr ',' '\n' | sed 's/"//g'))
                LAST_ELEMENT=$(echo ${SAMPLE[${#SAMPLE[@]}-1]})
                FETCH_STATE=""
                for row in $(echo "${STATE}" | jq -c '.[]'); do
                    CHUNK=$(echo $row | jq -r ${1})
                    FETCH_STATE=${FETCH_STATE}$(consul kv get "$CHUNK")
                    if [ "$LAST_ELEMENT" = "$CHUNK" ]; then
                        echo $FETCH_STATE | jq | tee -a ${s}.tfstate >/dev/null
                    fi
                done
            fi
            ./inframap-linux-amd64 generate ${s}.tfstate | dot -Tpng > ${s}_graph.png
            aws s3 cp ${s}_graph.png s3://s3-codepipeline-${APP_NAME}-${SHARED_LAYER}/inframap/
        done