variable "env_name" {
  type = string
}

variable "env_type" {
  type = string
}

variable "app_name" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

# variable "alb_listener_arn" {
#   type = string
# }

# variable "alb_test_listener_arn" {
#      type = string
#  }
 
# variable "alb_tg_blue_name" {
#   type = string
# }

# variable "alb_tg_green_name" {
#   type = string
# }

variable "ecs_iam_roles_arns" {
  type = list(string)
}

variable "termination_wait_time_in_minutes" {
  default = 120
}

variable appmesh_pipeline {
  type = bool 
  default = false
}

variable task_def_name {
  type = string
}

variable current_color {
  type = string
}