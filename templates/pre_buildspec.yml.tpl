version: 0.2

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - ECR_LOGIN=$(aws ecr get-login-password)
      - docker login --username AWS --password $ECR_LOGIN ${ECR_REPO_URL}
      - CODEBUILD_RESOLVED_SOURCE_VERSION="$CODEBUILD_RESOLVED_SOURCE_VERSION"
      - IMAGE_TAG="${FROM_ENV}"
  build:
    commands:
      - printf '[{"name":"%s","imageUri":"%s"}]' "$IMAGE_TAG" "${ECR_REPO_URL}" > image_definitions.json
      - aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition" --output json > taskdef.json
      - export var=$(aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition.taskDefinitionArn" --output text)
      - echo $APPSPEC > appspec.json

      - previous_version=$(cut -d ":" -f7 <<< $var)
      - version=$((previous_version+1))
      - var=$(sed "s/$previous_version/$version/g" <<< "$var")

      - sed -i "s+<TASKDEF_ARN>+$var+g" appspec.json
      - sed -i "s+<CONTAINER_NAME>+${TASK_DEF_NAME}+g" appspec.json

artifacts:
  files:
    - appspec.json
    - taskdef.json
  discard-paths: yes