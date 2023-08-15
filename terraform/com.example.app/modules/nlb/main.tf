resource "aws_lb" "l4_nlb" {
  name               = "example-ec2-${var.infra_env}"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnets
  tags               = {
    BillingGroup = var.project_name
    Environment = var.infra_env
    Name        = "${var.project_name}.${var.infra_env}"
  }
}


resource "aws_lb_target_group" "asg" {
  name                 = "example-ec2-${var.infra_env}"
  port                 = 80
  protocol             = "TCP"
  deregistration_delay = 10
  vpc_id               = var.vpc_id
  health_check {
    enabled             = true
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    protocol            = "TCP"
  }

}

resource "aws_lb_listener" "port_80" {
  load_balancer_arn    = aws_lb.l4_nlb.arn
  port                 = 80
  protocol             = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_listener" "port_443" {
  load_balancer_arn = aws_lb.l4_nlb.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}