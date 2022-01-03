variable "env_name" {
    type = string
}

variable "pipeline_type" {
  type = string
}

variable "source_repository" {
    type = string
}

variable "pre_codebuild_projects" {
    type = list(string)
}

variable "post_codebuild_projects" {
    type = list(string)
}

variable "code_deploy_applications" {
    type = list(string)
}

variable "s3_bucket" {
    type = string
}

variable "app_name" {
  default = "chorus"
}