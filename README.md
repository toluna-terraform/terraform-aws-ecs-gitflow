# terraform-aws-ecs-gitflow

This modules for for git flow of AWS ECS style applications 

### What is this repository for? ###

* Quick summary

This module helps implement gitflow in ECS style applications. 

* Version


* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)

### How do I get set up? ###

* Summary of set up

This module is included as part of applications. Usually will be called from terraform/app/pipeline.tf files, with parameters as follows: 


**General Parameters**

`from_env`

`env_name`

`app_name`

`env_type`

`source_repository`

`trigger_branch`

`pipeline_type`

`dockerfile_path`

`enable_jira_automation`

Boolean value (default: false), indicating if Jira automation to be enabled, to change the status of tickets after release is completed from AWS codepipeline.


This requires AWS SSM parameter `/app/jira_release_hook` to be setup along with required Jira automation. From the module,  the Jira release hook URL will be invoked and there by Jira automation will be executed to change the status of tickets as per the Jira automation configuration. 

**ECS related parameters**

`ecs_service_name`

`ecs_cluster_name`

`alb_listener_arn`

`alb_test_listener_arn`

`alb_tg_blue_name `

`alb_tg_green_name`

`ecr_registry_id`

`ecr_repo_name`

`ecr_repo_url`

`task_def_name`

**Testing Parameters**

`test_report_group`

`coverage_report_group`

`run_integration_tests`

`ecs_iam_roles_arns`

* Dependencies

* Database configuration

* How to run tests
* Deployment instructions

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Repo owner or admin
* Other community or team contact




