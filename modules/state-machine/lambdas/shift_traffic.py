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

  # --- switch traffic at appmesh route
  client = boto3.client("appmesh", region_name="us-east-1")
  response = client.update_route (
  meshName = "qa", 
  meshOwner = "532295357019", 
  virtualRouterName = "vr-chef-srinivas",
  routeName = "route-chef-srinivas", 
  spec= {
      'httpRoute': {
          'action': {
              'weightedTargets': [
                  {
                      'virtualNode': 'vn-{env}-{color}'.format(env = envName, color = currentColor),
                      'weight': 0
                  },
                  {
                      'virtualNode': 'vn-{env}-{color}'.format(env = envName, color = nextColor),
                      'weight': 100
                  }
              ]
          },
          'match': {
              'prefix': '/'
          }
      }
   }
  )

  # --- shutdown current previous color tasks after traffic switch
  client = boto3.client("ecs", region_name="us-east-1")
  
  print ("cluster_name = " + cluster_name)

  # shutdown curent_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = currentColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))

  # update current_color 
  ssm_resonse = ssm_client.put_parameter(
    Name = '/infra/{env}/current_color'.format(env = envName),
    Value = nextColor,
    Overwrite = True
  )
