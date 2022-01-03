##### DO NOT CHANGE INDENTATION !!! #####
        URL="https://api.bitbucket.org/2.0/repositories/tolunaengineering/${APP_NAME}/pullrequests/$PR_NUMBER/comments" && curl --request POST --url $URL -u "$USER:$PASS" --header "Accept:application/json" --header "Content-Type:application/json" --data "{\"content\":{\"raw\":\"$COMMENT\"}}"
