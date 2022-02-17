locals{
    codebuild_name = "codebuild-${var.codebuild_name}-${var.env_name}" 
}


resource "aws_codebuild_project" "codebuild" {
  name          = "${local.codebuild_name}"
  description   = "Build spec for ${local.codebuild_name}"
  build_timeout = "120"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    packaging = "NONE"
    override_artifact_name = false
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      
      content {
        name                 = environment_variable.key
        value                = environment_variable.value
      }

    }
      dynamic "environment_variable" {
        for_each = var.environment_variables_parameter_store
        
        content {
          name                 = environment_variable.key
          value                = environment_variable.value
          type                 = "PARAMETER_STORE"
        }

      }

      privileged_mode = var.privileged_mode  
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/${local.codebuild_name}/log-group"
      stream_name = "/${local.codebuild_name}/stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    #location        = var.source_repository_url
   # git_clone_depth = 1
    buildspec = var.buildspec_file
    
     # git_submodules_config {
    #   fetch_submodules = false
    # }
  }

   source_version =  var.source_branch

    tags = tomap({
                Name="codebuild-${local.codebuild_name}",
                environment=var.env_name,
                created_by="terraform"
    })
}

resource "aws_iam_role" "codebuild_role" {
  name = "role-${local.codebuild_name}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild_ecs_role" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess" // this policy should be changed to a new policy.
}

resource "aws_iam_role_policy" "cloudWatch_policy" {
  name = "policy-${local.codebuild_name}"
  role = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_role_policy.json
}