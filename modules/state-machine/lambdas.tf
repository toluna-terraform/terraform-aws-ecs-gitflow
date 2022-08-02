# ---- zipping py code and creating lambda for deploying updated version

data "archive_file" "deploy_updated_version_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/deploy_updated_version.py"
    output_path = "${path.module}/lambdas/deploy_updated_version.zip"
}

resource "aws_lambda_function" "deploy_updated_version" {
  runtime = "python3.8"

  function_name = "deploy_updated_version"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/deploy_updated_version.zip"
  # source_code_hash = "${data.archive_file.deploy_updated_version_zip.output_base64sha256}"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "deploy_updated_version.lambda_handler"
}

# # ---- zipping py code and creating lambda for HealthCheck

# data "archive_file" "health_check_zip" {
#     type        = "zip"
#     source_file  = "${path.module}/lambdas/health_check.py"
#     output_path = "${path.module}/lambdas/health_check.zip"
# }

# resource "aws_lambda_function" "health_check" {
#   runtime = "python3.8"

#   function_name = "health_check"
#   description = "Changes ECS service between blue and green "
#   filename = "${path.module}/lambdas/health_check.zip"
#   # source_code_hash = "${data.archive_file.health_check_zip.output_base64sha256}"

#   role = "${aws_iam_role.iam_for_lambda.arn}"
#   handler = "health_check.lambda_handler"
# }

# ---- zipping py code and creating lambda for Rollback

data "archive_file" "rollback_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/rollback.py"
    output_path = "${path.module}/lambdas/rollback.zip"
}

resource "aws_lambda_function" "rollback" {
  runtime = "python3.8"

  function_name = "rollback"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/rollback.zip"
  # source_code_hash = "${data.archive_file.rollback_zip.output_base64sha256}"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "rollback.lambda_handler"
}

# ---- zipping py code and creating lambda for run_integration_tests

data "archive_file" "run_integration_tests_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/run_integration_tests.py"
    output_path = "${path.module}/lambdas/run_integration_tests.zip"
}

resource "aws_lambda_function" "run_integration_tests" {
  runtime = "python3.8"

  function_name = "run_integration_tests"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/run_integration_tests.zip"
  # source_code_hash = "${data.archive_file.run_integration_tests_zip.output_base64sha256}"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "run_integration_tests.lambda_handler"
}

# ---- zipping py code and creating lambda that waits for git merge

data "archive_file" "wait_for_merge_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/wait_for_merge.py"
    output_path = "${path.module}/lambdas/wait_for_merge.zip"
}

resource "aws_lambda_function" "wait_for_merge" {
  runtime = "python3.8"

  function_name = "wait_for_merge"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/wait_for_merge.zip"
  # source_code_hash = "${data.archive_file.wait_for_merge_zip.output_base64sha256}"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "wait_for_merge.lambda_handler"
}

# ---- zipping py code and creating lambda for update ECS service
data "archive_file" "shift_traffic_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/shift_traffic.py"
    output_path = "${path.module}/lambdas/shift_traffic.zip"
}

resource "aws_lambda_function" "shift_traffic" {
  runtime = "python3.8"

  function_name = "shift_traffic"
  description = "Changes traffic between blue and green by switching route weight"
  filename = "${path.module}/lambdas/shift_traffic.zip"
  # source_code_hash = "${data.archive_file.shift_traffic_zip.output_base64sha256}"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "shift_traffic.lambda_handler"
}


