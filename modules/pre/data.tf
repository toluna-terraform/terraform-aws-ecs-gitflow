data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.s3_bucket
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "codebuild_role_policy" {
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
    actions   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:*",
            "ssm:*",
            "ecs:DescribeTaskDefinition",
            "cloudformation:*",
            "s3:*",
            "apigateway:*",
            "lambda:*"
        ]
    resources = ["*"]
  }
}