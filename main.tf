locals {
  image_uri = "${var.ecr_repo_url}:${var.from_env}"
  artifacts_bucket_name = "s3-codepipeline-${var.app_name}-${var.env_type}"
}

module "ci-cd-code-pipeline" {
  source                       = "./modules/ci-cd-codepipeline"
  env_name                     = var.env_name
  app_name                     = var.app_name
  pipeline_type                = var.pipeline_type
  source_repository            = var.source_repository
  s3_bucket                    = local.artifacts_bucket_name
  build_codebuild_projects     = [module.build.attributes.name]
  post_codebuild_projects      = [module.post.attributes.name]
  pre_codebuild_projects       = [module.pre.attributes.name]
  code_deploy_applications     = [module.code-deploy.attributes.name]
  depends_on = [
    module.build,
    module.code-deploy,
    module.post,
    module.pre
  ]
}


module "build" {
  source                                = "./modules/build"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "build-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = local.artifacts_bucket_name
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${var.app_name}", ENV_TYPE = "${var.env_type}", HOOKS = var.run_integration_tests, PIPELINE_TYPE = var.pipeline_type})}) //TODO: try to replace with file
  buildspec_file                        = templatefile("buildspec.yml.tpl", 
  { APP_NAME = var.app_name,
    ENV_TYPE = var.env_type,
    ENV_NAME = var.env_name,
    PIPELINE_TYPE = var.pipeline_type,
    IMAGE_URI = var.pipeline_type == "dev" ? "${var.ecr_repo_url}:${var.env_name}" : local.image_uri, 
    DOCKERFILE_PATH = var.dockerfile_path, 
    ECR_REPO_URL = var.ecr_repo_url, 
    ECR_REPO_NAME = var.ecr_repo_name,
    TASK_DEF_NAME = var.task_def_name, 
    ADO_USER = data.aws_ssm_parameter.ado_user.value, 
    ADO_PASSWORD = data.aws_ssm_parameter.ado_password.value,
    TEST_REPORT = var.test_report_group,
    CODE_COVERAGE_REPORT = var.coverage_report_group
  })
}


module "code-deploy" {
  source             = "./modules/codedeploy"
  env_name           = var.env_name
  env_type           = var.env_type
  app_name           = var.app_name
  s3_bucket          = "s3-codepipeline-${var.app_name}-${var.env_type}"
  ecs_service_name   = var.ecs_service_name
  ecs_cluster_name   = var.ecs_cluster_name
  alb_listener_arn   = var.alb_listener_arn
  alb_test_listener_arn   = var.alb_test_listener_arn
  alb_tg_blue_name   = var.alb_tg_blue_name
  alb_tg_green_name  = var.alb_tg_green_name
  ecs_iam_roles_arns = var.ecs_iam_roles_arns
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
}

module "pre" {
  source                                = "./modules/pre"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "pre-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${var.app_name}-${var.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${var.app_name}", ENV_TYPE = "${var.env_type}", HOOKS = var.run_integration_tests, PIPELINE_TYPE = var.pipeline_type})})
  buildspec_file                        = templatefile("${path.module}/templates/pre_buildspec.yml.tpl", 
  { ENV_NAME = var.env_name,
    APP_NAME = var.app_name,
    ENV_TYPE = var.env_type,
    PIPELINE_TYPE = var.pipeline_type,
    FROM_ENV = var.from_env,
    ECR_REPO_URL = var.ecr_repo_url, 
    ECR_REPO_NAME = var.ecr_repo_name,
    TASK_DEF_NAME = var.task_def_name 
    })
}



module "post" {
  source                                = "./modules/post"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "post-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${var.app_name}-${var.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  buildspec_file                        = templatefile("${path.module}/templates/post_buildspec.yml.tpl", 
  { ECR_REPO_URL = var.ecr_repo_url, 
    ECR_REPO_NAME = var.ecr_repo_name,
    ENV_NAME = split("-",var.env_name)[0],
    FROM_ENV = var.from_env,
    APP_NAME = var.app_name,
    ENV_TYPE = var.env_type
    })

}

