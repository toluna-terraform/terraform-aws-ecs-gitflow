version: 0.2

env:
  parameter-store:
    USER: "/app/bb_user"  
    PASS: "/app/bb_app_pass"
    RELEASE_HOOK_URL: "/app/jira_release_hook"

phases:
  pre_build:
    commands:
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
        REPORT_URL="https://console.aws.amazon.com/codesuite/codedeploy/applications/ecs-deploy-${ENV_NAME}/deployment-groups/ecs-deploy-group-${ENV_NAME}"
        URL="https://api.bitbucket.org/2.0/repositories/tolunaengineering/${APP_NAME}/commit/$COMMIT_ID/statuses/build/"
        curl --request POST --url $URL -u "$USER:$PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"key\":\"${APP_NAME} Deploy\",\"state\":\"SUCCESSFUL\",\"description\":\"Deployment to ${ENV_NAME} succeeded\",\"url\":\"$REPORT_URL\"}"    
      - |
        if [ "${ENV_NAME}" == "prod" ] && [ "${ENABLE_JIRA_AUTOMATION}" == "true" ] ; then 
          declare -a version=($(aws ecr describe-images --repository-name ${APP_NAME}-main --image-ids imageTag=${FROM_ENV} --query "imageDetails[0].imageTags[?Value==${FROM_ENV}]" --output text))
          export RELEASE_VERSION=$${version[1]}
          curl --request POST --url $RELEASE_HOOK_URL --header "Content-Type:application/json" --data "{\"data\": {\"releaseVersion\":\"$RELEASE_VERSION\"}}" || echo "No Jira to change"
        fi
      - |
        CORALOGIX_APIKEY=$(aws ssm get-parameter --name /infra/coralogix-tags/apikey --with-decryption --query 'Parameter.Value' --output text) 
        curl -X POST "https://webapi.coralogix.com/api/v1/external/tags" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $CORALOGIX_APIKEY" \
        -H "maskValue: false" \
        -d "{\"timestamp\":\""$(date +%s%N | cut -b1-13)"\",\"name\":\"${APP_NAME}-${ENV_NAME}-"$(date '+%Y-%m-%d')"\",\"application\":[\"${ENV_NAME}\"],\"subsystem\":[\"${APP_NAME}\"]}"
