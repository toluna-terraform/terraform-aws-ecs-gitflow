data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.s3_bucket
}
data "aws_iam_policy_document" "codedeploy_role_policy" {
  statement {
    actions   = [
            "ecs:DescribeServices",
            "ecs:CreateTaskSet",
            "ecs:UpdateServicePrimaryTaskSet",
            "ecs:DeleteTaskSet",
            "cloudwatch:DescribeAlarms"
        ]
    # TODO: replace with ecs arn
    resources = ["*"]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:*:*:CodeDeployTopic_*"]
  }
  statement {
    actions   = [
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule"
        ]
    resources = ["*"]
  }
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:*:*:function:CodeDeployHook_*"]
  }
  statement {
    actions   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
    resources = [
          "${data.aws_s3_bucket.codepipeline_bucket.arn}",
          "${data.aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = var.ecs_iam_roles_arns
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
}