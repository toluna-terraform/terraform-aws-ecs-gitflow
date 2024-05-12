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
      - |
        if [ "${PIPELINE_TYPE}" == "cd" ]; then 
          FULL_REGISTERY_NAME="${ECR_REPO_URL}"
          REGISTRY_ID="$${FULL_REGISTERY_NAME%%.*}"
          TARGET_TAG=$(aws ecr describe-images --repository-name "${ECR_REPO_NAME}" --image-ids imageTag=${FROM_ENV} --query "imageDetails[0].imageTags[?Value==${FROM_ENV}]" --output text --registry-id $REGISTRY_ID | grep -o -E '([0-9]+\.){2}[0-9]+(-[a-zA-Z0-9]+)?(\+[a-zA-Z0-9]+)?')
        else
          export TARGET_TAG="${FROM_ENV}"
        fi
  build:
    commands:
      - printf '{"ImageURI":"${ECR_REPO_URL}:%s"}' "$TARGET_TAG" > imageDetail.json
      - aws ecs describe-task-definition --task-definition ${TASK_DEF_NAME} --query "taskDefinition" --output json > tmp_taskdef_temp.json
      - sed -i -E 's/'${APP_NAME}':.*,/'${APP_NAME}':'$TARGET_TAG'",/' tmp_taskdef_temp.json
      - export CONTAINER_PORT=$(jq '.containerDefinitions[0].portMappings[0].containerPort' tmp_taskdef_temp.json)
      - jq '.containerDefinitions[0].environment[] |= if .name == "DD_VERSION" then .value = "'$TARGET_TAG'" else . end' tmp_taskdef_temp.json > tmp_taskdef_temp_with_version.json
      - jq 'del(.revision,.taskDefinitionArn,.status,.compatibilities,.requiresAttributes,.registeredAt,.registeredBy) | .containerDefinitions[0].image="<IMAGE1_NAME>"' tmp_taskdef_temp_with_version.json > taskdef.json
      - echo $APPSPEC > appspec.json
      - cat appspec.json
      - sed -i -E 's/<CONTAINER_PORT>/'$CONTAINER_PORT'/' appspec.json
      - sed -i -E 's/<CONTAINER_NAME>/${TASK_DEF_NAME}/' appspec.json

artifacts:
  files:
    - imageDetail.json
    - appspec.json
    - taskdef.json
  discard-paths: yes
  