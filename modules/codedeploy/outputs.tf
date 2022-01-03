output "attributes" {
     value = { for key, value in aws_codedeploy_app.codedeploy_app : key => value }
}
