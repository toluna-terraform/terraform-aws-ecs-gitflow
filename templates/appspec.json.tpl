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
    ],
    "Hooks": [
        %{ if HOOKS }
        {
            "AfterAllowTestTraffic": "${APP_NAME}-${ENV_TYPE}-test-framework"
        },
        %{ endif }
		{
            "BeforeAllowTraffic": "${APP_NAME}-${ENV_TYPE}-merge-waiter"
        }
    ]
}
