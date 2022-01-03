version: 0.2

phases:
  pre_build:
    commands:
      - ECR_LOGIN=$(aws ecr get-login-password)
      - docker login --username AWS --password $ECR_LOGIN ${ECR_REPO_URL}
      - CODEBUILD_RESOLVED_SOURCE_VERSION="$CODEBUILD_RESOLVED_SOURCE_VERSION"
      - COMMENT="Pipeline has been done successfully."
      - PR_NUMBER=$(cat pr.txt)
      - USER=$(echo $(aws ssm get-parameter --name /app/bb_user --with-decryption) | python3 -c "import sys, json; print(json.load(sys.stdin)['Parameter']['Value'])")
      - PASS=$(echo $(aws ssm get-parameter --name /app/bb_pass --with-decryption) | python3 -c "import sys, json; print(json.load(sys.stdin)['Parameter']['Value'])")
  build:
    commands:
      - MANIFEST=$(aws ecr batch-get-image --repository-name ${ECR_REPO_NAME} --image-ids imageTag=latest --output json | jq --raw-output '.images[0].imageManifest')
      - aws ecr put-image --repository-name ${ECR_REPO_NAME} --image-tag "ready_for_${NEXT_ENV}" --image-manifest "$MANIFEST" || true
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
