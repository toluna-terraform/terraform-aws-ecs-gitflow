import boto3
import json

def lambda_handler(event, context):


  envName = "chef-srinivas"
  currentColor = "green"
  appName = "chef"
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

  return { "messsage": "all is well" }