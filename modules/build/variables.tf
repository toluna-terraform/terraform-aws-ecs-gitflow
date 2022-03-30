 variable "env_name" {
     type     = string
 }

variable "env_type" {
  type = string
}

variable "codebuild_name" {
    type = string
  
}
  variable "s3_bucket" {
     type     = string
 }

 variable "source_repository" {
     type     = string
 }

variable "source_repository_url" {
    default  = "https://bitbucket.org/tolunaengineering/chorus.git"
    type     = string
 }

 variable "source_branch" {
     type     = string
     default = "master"
 }

 variable "buildspec_file" {
     type     = string
 }

variable "environment_variables" {
  default = {}  
  type        = map(string)
}

variable "environment_variables_parameter_store" {
 type = map(string)
 default = {
 "ADO_USER" = "/app/ado_user"
 "ADO_PASSWORD" = "/app/ado_password"
 }
}

variable "privileged_mode" { 
    type        = bool
    default     = true
    description = "set to true if building a docker"
}
