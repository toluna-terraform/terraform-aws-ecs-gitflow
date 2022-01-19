output "attributes" {
     value = { for key, value in aws_codebuild_project.tests_reports : key => value }
}
