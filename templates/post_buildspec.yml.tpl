version: 0.2

env:
  parameter-store:
    USER: "/app/bb_user"  
    PASS: "/app/bb_app_pass"
    CONSUL_PROJECT_ID: "/infra/${APP_NAME}-${ENV_NAME}/consul_project_id"
    CONSUL_HTTP_TOKEN: "/infra/${APP_NAME}-${ENV_NAME}/consul_http_token"

phases:
  pre_build:
    commands:
      - ECR_LOGIN=$(aws ecr get-login-password)
      - docker login --username AWS --password $ECR_LOGIN ${ECR_REPO_URL}
      - CODEBUILD_RESOLVED_SOURCE_VERSION="$CODEBUILD_RESOLVED_SOURCE_VERSION"
      - COMMENT="Pipeline has been done successfully."
      - PR_NUMBER=$(cat pr.txt)
      - SRC_CHANGED=$(cat src_changed.txt)
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
        ${UPDATE_BITBUCKET}
      - |
        CORALOGIX_APIKEY=$(aws ssm get-parameter --name /infra/coralogix-tags/apikey --with-decryption --query 'Parameter.Value' --output text) 
        curl -X POST "https://webapi.coralogix.com/api/v1/external/tags" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $CORALOGIX_APIKEY" \
        -H "maskValue: false" \
        -d "{\"timestamp\":\""$(date +%s%N | cut -b1-13)"\",\"name\":\"${APP_NAME}-${ENV_NAME}-"$(date '+%Y-%m-%d')"\",\"application\":[\"${ENV_NAME}\"],\"subsystem\":[\"${APP_NAME}\"]}"
