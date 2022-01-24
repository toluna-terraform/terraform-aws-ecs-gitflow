##### DO NOT CHANGE INDENTATION !!! #####
        export CONSUL_HTTP_ADDR=https://consul-cluster-test.consul.$CONSUL_PROJECT_ID.aws.hashicorp.cloud
        COMMIT_ID=$(consul kv get "infra/${APP_NAME}-${ENV_NAME}/commit_id")
        URL="https://api.bitbucket.org/2.0/repositories/tolunaengineering/$APP_NAME/commit/$COMMIT_ID/statuses/build/"
        EXEC_ID = $(aws codepipeline get-pipeline-state --region us-east-1 --name ${CODEBUILD_INITIATOR#codepipeline/} --query 'stageStates[?actionStates[?latestExecution.externalExecutionId==`'${CODEBUILD_BUILD_ID}'`]].latestExecution.pipelineExecutionId' --output text)
        LINK = "https://us-east-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/${CODEBUILD_INITIATOR}/executions/$EXEC_ID/timeline?region=us-east-1"
        curl --request POST --url $URL -u "$USER:$PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"key\":\"Pipeline Done - $CODEBUILD_INITIATOR\",\"state\":\"SUCCESSFUL\",\"description\":\"Pipeline done successfully.\",\"url\":\"$REPORT_URL\"}"
        URL="https://api.bitbucket.org/2.0/repositories/tolunaengineering/${APP_NAME}/pullrequests/$PR_NUMBER/comments" && curl --request POST --url $URL -u "$USER:$PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"content\":{\"raw\":\"$comment\"}}"
