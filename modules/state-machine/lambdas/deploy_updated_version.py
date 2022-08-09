import boto3
import json

def lambda_handler(event, context):

  envName = "chef-srinivas"
  appName = "chef"

  # getting current_color
  ssm_client = boto3.client("ssm", region_name="us-east-1")
  ssm_resonse = ssm_client.get_parameter (
    Name = "/infra/{env}/current_color".format(env = envName)
  )
  currentColor = ssm_resonse["Parameter"]["Value"]

  # deploying updated version
  client = boto3.client("ecs", region_name="us-east-1")
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
    desiredCount = 3,
    # updating taskdef
    taskDefinition = "{env}-{color}".format(env = envName, color = nextColor) ,
  )


