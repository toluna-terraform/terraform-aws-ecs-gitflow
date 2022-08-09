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

# Attach App mesh access
resource "aws_iam_policy_attachment" "attach-appmesh-policy" {
  name       = "attach-appmesh-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
}

# Attach ECS access
resource "aws_iam_policy_attachment" "attach-ecs-policy" {
  name       = "attach-ecs-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Attach SSM access
resource "aws_iam_policy_attachment" "attach-ssm-policy" {
  name       = "attach-ssm-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}