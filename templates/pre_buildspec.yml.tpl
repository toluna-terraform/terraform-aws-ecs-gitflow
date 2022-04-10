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
      - |
        if [ "${PIPELINE_TYPE}" == "cd" ] || [[ "$SRC_CHANGED" == "false" && "${PIPELINE_TYPE}" != "cd" ]]; then
          export FROM_ENV="${FROM_ENV}"
        else
          export FROM_ENV=$(cat new_version.txt)
        fi
  build:
    commands:
      - printf '{"ImageURI":"${ECR_REPO_URL}:%s"}' "$FROM_ENV" > imageDetail.json
      - aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition" --output json > tmp_taskdef_temp.json
      - sed -i -E 's/'${APP_NAME}'-main:.*,/'${APP_NAME}'-main:'$FROM_ENV'",/' tmp_taskdef_temp.json
      - jq '.containerDefinitions[0].environment[] |= if .name == "DD_VERSION" then .value = "'$FROM_ENV'" else . end' tmp_taskdef_temp.json > tmp_taskdef_temp_with_version.json
      - jq 'del(.revision,.taskDefinitionArn,.status,.compatibilities,.requiresAttributes,.registeredAt,.registeredBy) | .containerDefinitions[0].image="<IMAGE1_NAME>"' tmp_taskdef_temp_with_version.json > taskdef.json
      - echo $APPSPEC > appspec.json
      - cat appspec.json
      - sed -i -E 's/<CONTAINER_NAME>/${TASK_DEF_NAME}/' appspec.json

artifacts:
  files:
    - imageDetail.json
    - appspec.json
    - taskdef.json
  discard-paths: yes
  