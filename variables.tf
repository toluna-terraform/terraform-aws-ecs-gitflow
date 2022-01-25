variable "env_name" {
    type = string
}

variable "from_env" {
    type = string
}

variable "app_name" {
    type = string
}

variable "env_type" {
    type = string
}

variable "run_integration_tests" {
    type = bool
    default = false
}

variable "ecr_repo_url" {
    type = string 
}

variable "ecr_registry_id" {
    type = string
}

variable "task_def_name" {
    type = string
}

variable "source_repository" {
    type = string
}

variable "trigger_branch" {
    type     = string
 }

variable "dockerfile_path" {
    type = string
} 

 variable "ecs_cluster_name" {
     type = string
 }

variable "ecs_service_name" {
     type = string
 }

variable "alb_listener_arn" {
     type = string
 }

variable "alb_test_listener_arn" {
     type = string
 }
 
variable "alb_tg_blue_name" {
     type = string
 }

variable "alb_tg_green_name" {
     type = string
 }

variable "ecs_iam_roles_arns" {
     type = list(string)
     default = ["arn:aws:iam::047763475875:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"]
 }

 variable "ecr_repo_name" {
     type = string
 }

variable "environment_variables_parameter_store" {
 type = map(string)
 default = {
    "ADO_USER" = "/app/ado_user",
    "ADO_PASSWORD" = "/app/ado_password"
 }
}

variable "environment_variables" {
 type = map(string)
 default = {
 }
}

variable "pipeline_type" {
  type = string
}