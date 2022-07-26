resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test1_lambda" {

  runtime = "python3.9"

  s3_bucket     = data.aws_s3_object.s3_file1.bucket
  s3_key        = data.aws_s3_object.s3_file1.key

  function_name = "test1_function"
  role          = aws_iam_role.iam_for_lambda.arn
  # value should be file-name.handler-name
  handler       = "test1_function.lambda_handler"


}

resource "aws_lambda_function" "test2_lambda" {

  runtime = "python3.9"

  s3_bucket     = data.aws_s3_object.s3_file2.bucket
  s3_key        = data.aws_s3_object.s3_file2.key

  function_name = "test2_function"
  role          = aws_iam_role.iam_for_lambda.arn
  # value should be file-name.handler-name
  handler       = "test2_function.lambda_handler"


}

resource "aws_iam_role" "iam_for_sfn" {
  name = "iam_for_sfn"
  managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AWSLambdaRole" ]

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
              "Service": "states.amazonaws.com"
            },
           "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF
{
  "Comment": "A Hello World example of AWS Step functions using an AWS Lambda Function",
  "StartAt": "Task1",
  "States": {
    "Task1": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.test1_lambda.arn}",
      "Next": "Task2"
    },
    "Task2": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.test2_lambda.arn}",
      "End": true
    }
  }
}
EOF
}


