terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
  backend "s3" {
    shared_credentials_file = "/.aws/credentials"
    region                  = var.aws_region
    profile                 = var.aws_credentials_profile_name
  }
}

module "launch-template" {
  source                = "../modules/launch-template"
  project_name          = "com.example.app-develop"
  ami_name              = "ec2-with-codedeploy-and-docker"
  instance_profile_arn  = var.ec2_instance_profile_arn
  security_group_id     = var.ec2_security_group_id
  user_data_script_path = "../modules/launch-template/user_data_script.sh"
}

module "asg" {
  instance_count           = 1
  source                   = "../modules/asg"
  infra_env                = var.infra_env
  infra_launch_template_id = module.launch-template.launch_template_arn
  project_name             = var.project_name
  default_tags             = concat(local.extra_tags, [
    {
      key                 = "Name"
      value               = "${var.project_name}-${var.infra_env}"
      propagate_at_launch = true
    }
  ]
  )
  subnets           = var.subnets
  target_group_arns = [module.nlb.lb_tg_arn]
}

module "nlb" {
  source          = "../modules/nlb"
  certificate_arn = var.aws_acm_certificate_arn
  project_name    = var.project_name
  infra_env       = var.infra_env
  subnets         = var.subnets
}

module "codedeploy-deployment-group" {
  source                      = "../modules/codedeploy"
  codedeploy_service_role_arn = var.codedeploy_service_role_arn
  infra_env                   = var.infra_env
  project_name                = var.project_name
}