locals {
  prefix = "codebuild"
  codebuild_name = "source"
  suffix = "${var.app_name}-${var.env_name}"
  source_repository_url = "https://bitbucket.org/${var.source_repository}"
}

resource "aws_codebuild_webhook" "ci_webhook" {
  project_name = aws_codebuild_project.source_codebuild.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED,PULL_REQUEST_UPDATED"
    }

    filter {
      type    = "BASE_REF"
      pattern = var.trigger_branch
    }
  }
  count = var.pipeline_type == "ci" ? 1 : 0
}

resource "aws_codebuild_webhook" "cd_webhook" {
  project_name = aws_codebuild_project.source_codebuild.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }

    filter {
      type    = "BASE_REF"
      pattern = var.trigger_branch
    }

    filter {
      type    = "FILE_PATH"
      pattern = var.file_path_regex
    }
  }
  count = var.pipeline_type == "cd" ? 1 : 0
}


resource "aws_codebuild_project" "source_codebuild" {
  name          = "${local.prefix}-${local.codebuild_name}-${local.suffix}"
  description   = "Pull source files from Git repo"
  build_timeout = "120"
  service_role  = aws_iam_role.source_codebuild_iam_role.arn

  artifacts {
    packaging = "ZIP"
    type      = "S3"
    override_artifact_name = true
    location  = "s3-codepipeline-${var.app_name}-${var.env_type}"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/code_build/${local.codebuild_name}/log-group"
      stream_name = "/code_build/${local.codebuild_name}/stream"
    }
  }

  source {
    type     = "BITBUCKET"
    location = local.source_repository_url
    buildspec = templatefile("${path.module}/templates/buildspec-source.yml.tpl", { PIPELINE_TYPE = var.pipeline_type})
  }
  tags = tomap({
    Name        = "${local.prefix}-${local.codebuild_name}",
    environment = "${var.env_name}",
    created_by  = "terraform"
  })
}

resource "aws_iam_role" "source_codebuild_iam_role" {
  name               = "role-${local.codebuild_name}-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "source_codebuild_iam_policy" {
  role = aws_iam_role.source_codebuild_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" // this policy should be changed to a new policy.
}

resource "aws_s3_bucket_object" "folder" {
    bucket = "s3-codepipeline-${var.app_name}-${var.env_type}"
    acl    = "private"
    key    = var.pipeline_type
}