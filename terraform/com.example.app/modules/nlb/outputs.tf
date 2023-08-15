output "lb_arn" {
  value = aws_lb.l4_nlb.arn
}

output "lb_tg_arn" {
  value = aws_lb_target_group.asg.arn
}