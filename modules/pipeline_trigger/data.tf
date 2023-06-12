data "aws_iam_policy_document" "inline_merge_status_update_policy_doc" {
  statement {
    actions = [
      "ssm:*"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "states:*"
    ]
    resources = ["*"]
  }
}

data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "s3-codepipeline-${var.app_name}-${var.env_type}"
}