resource "aws_codedeploy_deployment_group" "a" {
  app_name              = var.parent_codedeploy_app_name
  deployment_group_name = "${var.infra_env}"
  service_role_arn      = var.codedeploy_service_role_arn

  autoscaling_groups = [
    "${var.project_name}-${var.infra_env}"
  ]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}