locals {
  codepipeline_name     = "codepipeline-${var.app_name}-${var.env_name}"
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
        S3Bucket = "${var.s3_bucket}"
        S3ObjectKey = "${var.env_name}/source_artifacts.zip"
        PollForSourceChanges = true
        
      }
    }
  }


  stage {
    name = "CI"
    dynamic "action" {
      for_each = var.build_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"
        output_artifacts = ["ci_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }


    stage {
    name = "Pre-Deploy"
    dynamic "action" {
      for_each = var.pre_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["ci_output"]
        version          = "1"
        output_artifacts = ["cd_output"]

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
        input_artifacts = ["cd_output"]
        version         = "1"
        configuration = {
          ApplicationName = action.value
          DeploymentGroupName = "ecs-deploy-group-${var.env_name}"
          TaskDefinitionTemplateArtifact = "cd_output"
          AppSpecTemplateArtifact = "cd_output"
          
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
  name               = "role-${local.codepipeline_name}"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "policy-${local.codepipeline_name}"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

