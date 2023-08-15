output "ec2_security_group_arn" {
  value = "${aws_security_group.instance_sg.arn}"
}

output "ecs_subnet_c_id" {
  value = "${aws_subnet.subnet_c.id}"
}

output "ecs_subnet_b_id" {
  value = "${aws_subnet.subnet_b.id}"
}

output "security_group_id" {
  value = "${aws_security_group.instance_sg.id}"
}

output "iam_instance_profile_arn" {
  value = aws_iam_instance_profile.instance_profile.arn
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.instance_profile.name
}

output "aws_iam_role_arn" {
  value = aws_iam_role.codedeploy.arn
}