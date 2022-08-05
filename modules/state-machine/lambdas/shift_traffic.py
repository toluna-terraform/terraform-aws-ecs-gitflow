import boto3
import json

def lambda_handler(event, context):

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
              'method': 'POST',
              'path': {
                  'exact': '/'
              }
          }
      }
   }
  )

  # --- shutdown current previous color tasks after traffic switch
  client = boto3.client("ecs", region_name="us-east-1")
  
  envName = "chef-srinivas"
  currentColor = "green"
  appName = "chef"
  if currentColor == "green":
    nextColor = "blue"
  else:
    nextColor = "green"

  clusters = client.list_clusters()
  cluster_name = clusters['clusterArns'][3]
  print ("cluster_name = " + cluster_name)

  # shutdown curent_color tasks
  response = client.update_service(
    cluster = cluster_name,
    service = "{app}-{color}".format(app = appName, color = currentColor) ,
    desiredCount = 0
  )
  print( json.dumps(response, indent=4, default=str))
