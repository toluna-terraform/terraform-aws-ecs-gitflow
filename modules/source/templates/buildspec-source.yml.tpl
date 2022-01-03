# code_build spec for pulling source from BitBucket
version: 0.2

phases:
  pre_build:
    commands:
      - printenv
      - head=$(echo $CODEBUILD_WEBHOOK_HEAD_REF | awk -F/ '{print $NF}')
      - base=$(echo $CODEBUILD_WEBHOOK_BASE_REF | awk -F/ '{print $NF}')
      - git diff --name-only origin/$head origin/$base --raw >> diff_results.txt
      - PR_NUMBER="$(echo $CODEBUILD_WEBHOOK_TRIGGER | cut -d'/' -f2)"
  install:
    runtime-versions:
      docker: 18
  build:
    commands:
      - echo Build started on `date`
  post_build:
    commands:
      - if grep -q "terraform" diff_results.txt; then aws codebuild stop-build --id $CODEBUILD_BUILD_ID; fi
      - rm -rf diff_results.txt
      - echo $PR_NUMBER > pr.txt
    
artifacts:
  files:
    - '**/*'
  discard-paths: no
  name: ${PIPELINE_TYPE}/source_artifacts.zip