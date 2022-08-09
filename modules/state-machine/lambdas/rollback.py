import boto3
import json

def lambda_handler(event, context):

  envName = "chef-srinivas"
  appName = "chef"
  cluster_name = "chef-srinivas"

  # getting current_color
  ssm_client = boto3.client("ssm", region_name="us-east-1")
  ssm_resonse = ssm_client.get_parameter    (
    Name = '/infra/{env}/current_color'.format(env = envName)
  )
  currentColor = ssm_resonse["Parameter"]["Value"]
  
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"


  # --- shutdown current next color tasks after traffic switch
  client = boto3.client("ecs", region_name="us-east-1")

  # shutdown next_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = nextColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

