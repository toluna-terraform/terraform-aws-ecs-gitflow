locals {
  app_name               = var.app_name == null ? var.pipeline_config.app_name : var.app_name
  ecr_repo_url           = var.ecr_repo_url == null ? var.pipeline_config.ecr_repo_url : var.ecr_repo_url
  ecr_repo_name          = var.ecr_repo_name == null ? var.pipeline_config.ecr_repo_name : var.ecr_repo_name
  from_env               = var.from_env == null ? var.pipeline_config.from_env : var.from_env
  env_type               = var.env_type == null ? var.pipeline_config.env_type : var.env_type
  env_name               = var.env_name == null ? var.pipeline_config.env_name : var.env_name
  pipeline_type          = var.pipeline_type == null ? var.pipeline_config.pipeline_type : var.pipeline_type
  ecs_service_name       = var.ecs_service_name == null ? var.pipeline_config.ecs_service_name : var.ecs_service_name
  ecs_cluster_name       = var.ecs_cluster_name == null ? var.pipeline_config.ecs_cluster_name : var.ecs_cluster_name
  task_def_name          = var.task_def_name == null ? var.pipeline_config.task_def_name : var.task_def_name
  run_integration_tests  = var.run_integration_tests == null ? var.pipeline_config.run_integration_tests : var.run_integration_tests
  test_report_group      = var.test_report_group == null ? var.pipeline_config.test_report_group : var.test_report_group
  coverage_report_group  = var.coverage_report_group == null ? var.pipeline_config.coverage_report_group : var.coverage_report_group
  enable_jira_automation = var.enable_jira_automation == null ? var.pipeline_config.enable_jira_automation : var.enable_jira_automation
  dockerfile_path        = var.dockerfile_path == null ? "service/${local.app_name}" : var.dockerfile_path
  source_repository      = var.source_repository == null ? "tolunaengineering/${local.app_name}" : var.source_repository
  artifacts_bucket_name  = "s3-codepipeline-${local.app_name}-${local.env_type}"
  run_tests              = local.run_integration_tests || var.run_stress_tests ? true : false
  image_uri              = "${local.ecr_repo_url}:${local.from_env}"
  vpc_config             = var.vpc_config.vpc_id == "NULL" ? merge(var.pipeline_config.vpc_config, { security_group_ids = var.security_group_ids }) : var.vpc_config
}

module "ci-cd-code-pipeline" {
  source                   = "./modules/ci-cd-codepipeline"
  env_name                 = local.env_name
  app_name                 = local.app_name
  pipeline_type            = local.pipeline_type
  source_repository        = local.source_repository
  s3_bucket                = local.artifacts_bucket_name
  build_codebuild_projects = [module.build.attributes.name]
  post_codebuild_projects  = [module.post.attributes.name]
  pre_codebuild_projects   = [module.pre.attributes.name]
  code_deploy_applications = [module.code-deploy.attributes.name]

  depends_on = [
    module.build,
    module.code-deploy,
    module.post,
    module.pre
  ]
}


module "build" {
  source                                = "./modules/build"
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "build-${local.app_name}"
  source_repository                     = local.source_repository
  codebuild_env_instance_type           = var.codebuild_env_instance_type
  s3_bucket                             = local.artifacts_bucket_name
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  vpc_config                            = local.vpc_config
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${local.app_name}", ENV_TYPE = "${local.env_type}", HOOKS = local.run_tests, PIPELINE_TYPE = local.pipeline_type }) }) //TODO: try to replace with file
  buildspec_file = templatefile("buildspec.yml.tpl",
    { APP_NAME             = local.app_name,
      ENV_TYPE             = local.env_type,
      ENV_NAME             = local.env_name,
      PIPELINE_TYPE        = local.pipeline_type,
      IMAGE_URI            = local.pipeline_type == "dev" ? "${local.ecr_repo_url}:${local.env_name}" : local.image_uri,
      DOCKERFILE_PATH      = local.dockerfile_path,
      ECR_REPO_URL         = local.ecr_repo_url,
      ECR_REPO_NAME        = local.ecr_repo_name,
      TASK_DEF_NAME        = local.task_def_name,
      ADO_USER             = data.aws_ssm_parameter.ado_user.value,
      ADO_PASSWORD         = data.aws_ssm_parameter.ado_password.value,
      TEST_REPORT          = local.test_report_group,
      CODE_COVERAGE_REPORT = local.coverage_report_group
  })
}


module "code-deploy" {
  source                           = "./modules/codedeploy"
  env_name                         = local.env_name
  env_type                         = local.env_type
  app_name                         = local.app_name
  s3_bucket                        = "s3-codepipeline-${local.app_name}-${local.env_type}"
  ecs_service_name                 = local.ecs_service_name
  ecs_cluster_name                 = local.ecs_cluster_name
  alb_listener_arn                 = var.alb_listener_arn
  alb_test_listener_arn            = var.alb_test_listener_arn
  alb_tg_blue_name                 = var.alb_tg_blue_name
  alb_tg_green_name                = var.alb_tg_green_name
  ecs_iam_roles_arns               = var.ecs_iam_roles_arns
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
}


module "pre" {
  source                                = "./modules/pre"
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "pre-${local.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${local.app_name}-${local.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${local.app_name}", ENV_TYPE = "${local.env_type}", HOOKS = local.run_integration_tests, PIPELINE_TYPE = local.pipeline_type }) })
  buildspec_file = templatefile("${path.module}/templates/pre_buildspec.yml.tpl",
    { ENV_NAME      = local.env_name,
      APP_NAME      = local.app_name,
      ENV_TYPE      = local.env_type,
      PIPELINE_TYPE = local.pipeline_type,
      FROM_ENV      = local.from_env,
      ECR_REPO_URL  = local.ecr_repo_url,
      ECR_REPO_NAME = local.ecr_repo_name,
      TASK_DEF_NAME = local.task_def_name
  })
}


module "post" {
  source                                = "./modules/post"
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "post-${local.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${local.app_name}-${local.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  enable_jira_automation                = local.enable_jira_automation

  buildspec_file = templatefile("${path.module}/templates/post_buildspec.yml.tpl",
    { ECR_REPO_URL           = local.ecr_repo_url,
      ECR_REPO_NAME          = local.ecr_repo_name,
      ENV_NAME               = local.env_name,
      FROM_ENV               = local.from_env,
      APP_NAME               = local.app_name,
      ENV_TYPE               = local.env_type,
      ENABLE_JIRA_AUTOMATION = local.enable_jira_automation
  })
}
