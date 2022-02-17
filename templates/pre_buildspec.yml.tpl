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
  build:
    commands:
      - printf '[{"name":"%s","imageUri":"%s"}]' "${FROM_ENV}" "${ECR_REPO_URL}" > image_definitions.json
      - aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition" --output json > taskdef.json
      - sed -i -E 's/'${APP_NAME}'-main:.*,/'${APP_NAME}'-main:'${FROM_ENV}'",/' taskdef.json
      - jq 'del(.revision,.taskDefinitionArn,.status,.compatibilities,.requiresAttributes,.registeredAt,.registeredBy)' taskdef.json > new_taskdef.json
      - export var=$(aws ecs register-task-definition --cli-input-json file://new_taskdef.json --query "taskDefinition.taskDefinitionArn" --output text)
      - cat new_taskdef.json
      - echo "current td arn version :::$var"
      - echo $APPSPEC > appspec.json
      - echo "Setting Task Definition version:::$var"
      - sed -i "s+<TASKDEF_ARN>+$var+g" appspec.json
      - cat appspec.json
      - sed -i "s+<CONTAINER_NAME>+${TASK_DEF_NAME}+g" appspec.json

          

artifacts:
  files:
    - appspec.json
    - taskdef.json
  discard-paths: yes
