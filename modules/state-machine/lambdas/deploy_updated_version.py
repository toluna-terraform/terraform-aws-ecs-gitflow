import boto3
import json

def lambda_handler(event, context):

  client = boto3.client("ecs", region_name="us-east-1")


  envName = "chef-srinivas"
  currentColor = "green"
  appName = "chef"
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

  cluster_name = "chef-srinivas"
  print ("cluster_name = " + cluster_name)


  # start next_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = nextColor) ,
    
    # updating taskdef
    taskDefinition = "{env}-{color}".format(env = envName, color = nextColor) ,
  )


