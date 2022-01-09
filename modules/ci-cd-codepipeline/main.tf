locals {
  repository_name       = split("/", var.source_repository)[1]
  artifacts_bucket_name = "s3-codepipeline-${local.repository_name}-${var.env_name}"
  codepipeline_name     = "codepipeline-${var.pipeline_type}-${local.repository_name}-${var.env_name}"
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Download_Merged_Sources"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket = "s3-source-codebuild-${var.app_name}-${var.env_name}"
        S3ObjectKey = "ci/source_artifacts.zip"
        PollForSourceChanges = true
        
      }
    }
  }

    stage {
    name = "Pre"
    dynamic "action" {
      for_each = var.pre_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"
        output_artifacts = ["build_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

  stage {
    name = "Build"
    dynamic "action" {
      for_each = var.build_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"
        output_artifacts = ["build_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

  stage {
    name = "Deploy"
    dynamic "action" {
      for_each = var.code_deploy_applications
      content {
        name            = action.value
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeployToECS"
        input_artifacts = ["build_output"]
        version         = "1"
        configuration = {
          ApplicationName = action.value
          DeploymentGroupName = "ecs-deploy-group-${var.env_name}"
          TaskDefinitionTemplateArtifact = "build_output"
          AppSpecTemplateArtifact = "build_output"
          
        }
      }
    }
  }

    stage {
    name = "Post-Deploy"
    dynamic "action" {
      for_each = var.post_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${local.codepipeline_name}-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

