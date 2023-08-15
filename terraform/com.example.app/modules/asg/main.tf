resource "aws_autoscaling_group" "asg" {
  name                = "${var.project_name}-${var.infra_env}"
  vpc_zone_identifier = var.subnets
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  target_group_arns   = var.target_group_arns


  dynamic "tag" {
    for_each = var.default_tags
    content {
      key                 = tag.value.key
      propagate_at_launch = tag.value.propagate_at_launch
      value               = tag.value.value
    }
  }
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_name = "${var.project_name}-${var.infra_env}"
        version              = "$Latest"
      }
      override {
        instance_type = var.ec2_instance_type
      }
    }
  }
}