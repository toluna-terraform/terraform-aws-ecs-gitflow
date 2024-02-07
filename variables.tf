variable "pipeline_config" {
}

variable "env_name" {
  type     = string
  default  = null
}

variable "from_env" {
  type     = string
  default  = null
}

variable "app_name" {
  type     = string
  default  = null
}

variable "env_type" {
  type     = string
  default  = null
}

variable "run_integration_tests" {
  type     = bool
  default  = null
}

variable "run_stress_tests" {
  type    = bool
  default = false
}

variable "ecr_repo_url" {
  type     = string
  default  = null
}

variable "ecr_registry_id" {
  type     = string
  default  = null
}

variable "task_def_name" {
  type     = string
  default  = null
}

variable "source_repository" {
  type     = string
  default  = null
}

variable "trigger_branch" {
  type     = string
  default  = null
}

variable "dockerfile_path" {
  type     = string
  default  = null
}

variable "ecs_cluster_name" {
  type     = string
  default  = null
}

variable "ecs_service_name" {
  type     = string
  default  = null
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
  type    = list(string)
  default = ["arn:aws:iam::047763475875:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"]
}

variable "ecr_repo_name" {
  type     = string
  default  = null
}

variable "environment_variables_parameter_store" {
  type = map(string)
  default = {
    "ADO_USER"     = "/app/ado_user",
    "ADO_PASSWORD" = "/app/ado_password"
  }
}

variable "environment_variables" {
  type = map(string)
  default = {
  }
}

variable "pipeline_type" {
  type     = string
  default  = null
}

variable "codebuild_env_instance_type" {
  type    = string
  default = "BUILD_GENERAL1_SMALL"
}

variable "termination_wait_time_in_minutes" {
  default = 120
}

variable "test_report_group" {
  type     = string
  default  = null
}

variable "coverage_report_group" {
  type     = string
  default  = null
}

variable "enable_jira_automation" {
  type        = bool
  description = "flag to indicate if Jira automation is enabled"
  default     = null
}

variable "vpc_config" {
  default = {
     vpc_id             = "NULL",
      subnets            = [],
      security_group_ids = []
  }
}

variable "security_group_ids" {
  type = list(string)
  default = []
}
