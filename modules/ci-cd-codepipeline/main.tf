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
        PollForSourceChanges = false
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
        output_artifacts = var.pipeline_type == "dev" ? ["dev_output"] : ["cd_output"]

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
        input_artifacts = var.pipeline_type == "dev" ? ["dev_output"] : ["cd_output"]
        version         = "1"
        configuration = {
          ApplicationName = action.value
          DeploymentGroupName = "ecs-deploy-group-${var.app_name}-${var.env_name}"
          TaskDefinitionTemplateArtifact = var.pipeline_type == "dev" ? "dev_output" : "cd_output"
          TaskDefinitionTemplatePath = "taskdef.json"
          AppSpecTemplateArtifact = var.pipeline_type == "dev" ? "dev_output" : "cd_output"
          Image1ArtifactName = var.pipeline_type == "dev" ? "dev_output" : "cd_output"
          Image1ContainerName = "IMAGE1_NAME"
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

resource "aws_cloudwatch_event_rule" "trigger_pipeline" {
  name        = "${local.codepipeline_name}-trigger"
  description = "Trigger ${local.codepipeline_name}"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject", "CompleteMultipartUpload", "CopyObject"],
      "requestParameters" : {
        "bucketName" : ["${var.s3_bucket}"],
        "key" : ["${var.env_name}/source_artifacts.zip"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_pipeline" {
  rule      = aws_cloudwatch_event_rule.trigger_pipeline.name
  target_id = "${local.codepipeline_name}"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.codepipeline_role.arn
}