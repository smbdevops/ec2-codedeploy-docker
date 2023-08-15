variable project_name {
  type        = string
  description = "used for prefixing resources"
  default     = "com.example.app"
}

variable ec2_instance_size {
  type        = string
  description = "Size of the EC2 instances that are running Docker in the ASG"
}

variable "infra_env" {
  type        = string
  description = "also used for prefixing and naming resources"
  default     = "develop"
}

variable "codedeploy_service_role_arn" {
  type        = string
  description = "Role for CodeDeploy service to use"
}


variable "ec2_instance_profile_arn" {
  type        = string
  description = "EC2 Instance Profile ARN"
}

variable "ec2_security_group_id" {
  type        = string
  description = "SG for EC2 host"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets to launch EC2 instances and Network Load Balancers from"
}

variable "aws_region" {
  type = string
  description = "AWS Region to use"
  default = "us-west-1"
}

variable "aws_credentials_profile_name" {
  type = string
  description = "AWS Credentials profile to use. Refer to ~/.aws/credentials."
}

variable "aws_acm_certificate_arn" {
  type = string
  description = "AWS-managed TLS Certificate ARN"
}