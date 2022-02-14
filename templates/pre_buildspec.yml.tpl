version: 0.2

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - BUILD_CONDITION=$(cat ci.txt)
      - PR_NUMBER=$(cat pr.txt)
      - SRC_CHANGED=$(cat src_changed.txt)
      - IMAGE_TAG="${FROM_ENV}";
  build:
    commands:
      - printf '[{"name":"%s","imageUri":"%s"}]' "$IMAGE_TAG" "${ECR_REPO_URL}" > image_definitions.json
      - aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition" --output json > taskdef.json
      - sed -i -E 's/'$APP_NAME'-main:.*"/'$APP_NAME'-main:'$IMAGE_TAG'"/' taskdef.json
      
      - export var=$(aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition.taskDefinitionArn" --output text)
      - echo $APPSPEC > appspec.json
      - previous_version=$(cut -d ":" -f7 <<< $var)
      - version=$((previous_version+1))
      - var=$(sed 's/$APP_NAME-$ENV_NAME:$previous_version/$APP_NAME-$ENV_NAME:$version/g' <<< "$var")

      - sed -i "s+<TASKDEF_ARN>+$var+g" appspec.json
      - cat appspec.json
      - sed -i "s+<CONTAINER_NAME>+${TASK_DEF_NAME}+g" appspec.json

artifacts:
  files:
    - appspec.json
    - taskdef.json
  discard-paths: yes
