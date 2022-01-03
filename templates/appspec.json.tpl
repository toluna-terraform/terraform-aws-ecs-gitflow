{
    "version": 0.0,
    "Resources": [
        {
            "TargetService": {
                "Type": "AWS::ECS::Service",
                "Properties": {
                    "TaskDefinition": "<TASKDEF_ARN>",
                    "LoadBalancerInfo": {
                        "ContainerName": "<CONTAINER_NAME>",
                        "ContainerPort": 80
                    }
                }               
            }
        }
    ]
}
