variable instance_count {
  type        = number
  description = "The daily desired count of instances."
  default     = 1
}

variable target_group_arns {
  type = list(string)
  description = "list of target groups to attach to"
}


variable project_name {
  type        = string
  description = "name of the project -- prefixes the infra_env typically"
}

variable infra_env {
  type        = string
  description = "name of the environment (develop || production )"
}

variable infra_launch_template_id {
  type        = string
  description = "Launch Template ID to use"
}

variable pager_duty_sns_arn {
  type        = string
  description = "Pager Duty sns arn"
  default     = "arn:aws:sns:us-west-1:848116219031:PagerDuty"
}

variable "default_tags" {
  type = list(object({
    key                 = string
    value               = string
    propagate_at_launch = bool
  }))
  default = []
}

variable "ec2_instance_type" {
  type        = string
  description = "Default instance size"
  default     = "t3.small"
}
variable "subnets" {
  type    = list(string)
  description = "subnets to run instances in"
}