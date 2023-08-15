locals {
  extra_tags = [
    {
      key                 = "Environment"
      value               = var.infra_env
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = var.project_name
      propagate_at_launch = true
    }
  ]
}