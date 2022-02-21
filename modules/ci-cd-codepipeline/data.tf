data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.s3_bucket
}

data "aws_ssm_parameter" "codepipeline_connection_arn" {
  name = "/infra/codepipeline/connection_arn"
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = ["*"]
  }
  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "codedeploy:*"
      # "codedeploy:CreateDeployment",
      # "codedeploy:GetApplicationRevision",
      # "codedeploy:GetDeployment",
      # "codedeploy:GetDeploymentConfig",
      # "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    actions   = [
            "ecs:*"
        ]
    # TODO: replace with ecs arn
    resources = ["*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = [
        "arn:aws:iam::*:role/role-ecs-${var.app_name}-${var.env_name}",
        ]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values = ["ecs-tasks.amazonaws.com"]
    }
  }
    statement {
    actions = [
                "ecr:PutImageTagMutability",
                "ecr:StartImageScan",
                "ecr:DescribeImageReplicationStatus",
                "ecr:ListTagsForResource",
                "ecr:UploadLayerPart",
                "ecr:BatchDeleteImage",
                "ecr:CreatePullThroughCacheRule",
                "ecr:ListImages",
                "ecr:BatchGetRepositoryScanningConfiguration",
                "ecr:DeleteRepository",
                "ecr:GetRegistryScanningConfiguration",
                "codebuild:BatchGetBuilds",
                "codestar-connections:UseConnection",
                "codedeploy:*",
                "ecr:CompleteLayerUpload",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:BatchCheckLayerAvailability",
                "ecr:ReplicateImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetRegistryPolicy",
                "ecr:PutLifecyclePolicy",
                "ecr:DescribeImageScanFindings",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:CreateRepository",
                "ecr:DescribeRegistry",
                "ecr:PutImageScanningConfiguration",
                "ecr:GetDownloadUrlForLayer",
                "ecr:DescribePullThroughCacheRules",
                "ecr:GetAuthorizationToken",
                "ecr:PutRegistryScanningConfiguration",
                "ecr:DeletePullThroughCacheRule",
                "ecr:DeleteLifecyclePolicy",
                "ecr:PutImage",
                "ecr:UntagResource",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecs:*",
                "ecr:StartLifecyclePolicyPreview",
                "codebuild:StartBuild",
                "ecr:InitiateLayerUpload",
                "ecr:GetRepositoryPolicy",
                "ecr:PutReplicationConfiguration"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.app_name}-main"]
  }
}
