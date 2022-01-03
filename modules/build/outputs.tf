output "attributes" {
     value = { for key, value in aws_codebuild_project.codebuild : key => value }
}
