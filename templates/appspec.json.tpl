{
    "version": 0.0,
    "Resources": [
        {
            "TargetService": {
                "Type": "AWS::ECS::Service",
                "Properties": {
                    "TaskDefinition": "<TASK_DEFINITION>",
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
        %{ if PIPELINE_TYPE != "dev" }
		{
            "BeforeAllowTraffic": "${APP_NAME}-${ENV_TYPE}-merge-waiter"
        }
        %{ endif }
    ]
}
