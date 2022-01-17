variable "env_name" {
  type = string
}

variable "env_type" {
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

variable "alb_listener_arn" {
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
}
