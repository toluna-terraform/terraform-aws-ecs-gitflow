locals {
  image_uri = "${var.ecr_repo_url}:latest"
  artifacts_bucket_name = "s3-codepipeline-${var.app_name}-${var.env_type}"
}

module "ci-cd-code-pipeline" {
  source                       = "./modules/ci-cd-codepipeline"
  env_name                     = var.env_name
  app_name                     = var.app_name
  pipeline_type                = var.pipeline_type
  source_repository            = var.source_repository
  s3_bucket                    = "s3-codepipeline-${var.app_name}-${var.env_type}"
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
  count = var.pipeline_type == "ci-cd" ? 1 : 0
}

module "ci-code-pipeline" {
  source                       = "./modules/ci-codepipeline"
  env_name                     = var.env_name
  app_name                     = var.app_name
  env_type                     = var.env_type
  pipeline_type                = var.pipeline_type
  source_repository            = var.source_repository
  s3_bucket                    = "s3-codepipeline-${var.app_name}-${var.env_type}"
  build_codebuild_projects     = [module.build[0].attributes.name]
  post_codebuild_projects      = [module.post.attributes.name]
  code_deploy_applications     = [module.code-deploy.attributes.name]
  depends_on = [
    module.build,
    module.code-deploy,
    module.post
  ]
  count = var.pipeline_type == "ci" ? 1 : 0
}


module "cd-code-pipeline" {
  source                       = "./modules/cd-codepipeline"
  env_name                     = var.env_name
  app_name                     = var.app_name
  env_type                     = var.env_type
  pipeline_type                = var.pipeline_type
  source_repository            = var.source_repository
  pre_codebuild_projects     = [module.pre.attributes.name]
  post_codebuild_projects      = [module.post.attributes.name]
  s3_bucket                    = "s3-codepipeline-${var.app_name}-${var.env_type}"
  code_deploy_applications     = [module.code-deploy.attributes.name]
  depends_on = [
    module.code-deploy
  ]
  count = var.pipeline_type == "cd" ? 1 : 0
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
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { yoyo = "yo" }) }) //TODO: try to replace with file
  buildspec_file                        = templatefile("buildspec.yml.tpl", 
  { IMAGE_URI = local.image_uri, 
    DOCKERFILE_PATH = var.dockerfile_path, 
    ECR_REPO_URL = var.ecr_repo_url, 
    ECR_REPO_NAME = var.ecr_repo_name,
    TASK_DEF_NAME = var.task_def_name, 
    ADO_USER = data.aws_ssm_parameter.ado_user.value, 
    ADO_PASSWORD = data.aws_ssm_parameter.ado_password.value })
}


module "code-deploy" {
  source             = "./modules/codedeploy"
  env_name           = var.env_name
  env_type           = var.env_type
  pipeline_type      = var.pipeline_type
  s3_bucket          = "s3-codepipeline-${var.app_name}-${var.env_type}"
  ecs_service_name   = var.ecs_service_name
  ecs_cluster_name   = var.ecs_cluster_name
  alb_listener_arn   = var.alb_listener_arn
  alb_tg_blue_name   = var.alb_tg_blue_name
  alb_tg_green_name  = var.alb_tg_green_name
  ecs_iam_roles_arns = var.ecs_iam_roles_arns

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
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { yoyo = "yo" }) }) //TODO: try to replace with file
  buildspec_file                        = templatefile("${path.module}/templates/pre_buildspec.yml.tpl", 
  { ENV_NAME = var.env_name,
    APP_NAME = var.app_name,
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
    ENV_NAME = var.env_name,
    FROM_ENV = var.from_env,
    APP_NAME = var.app_name,
    UPDATE_BITBUCKET = templatefile("${path.module}/templates/update_bitbucket.sh.tpl", { APP_NAME = var.app_name })
    })

}

