variable project_name {
  type        = string
  description = "name of the project -- prefixes the infra_env typically"
}

variable parent_codedeploy_app_name {
  type        = string
  description = "App name for codedeploy deployment group creation"
  default     = "com.example.app"
}

variable "codedeploy_service_role_arn" {
  type        = string
  description = <<EOT
For EC2/On-Premises deployments, attach the AWSCodeDeployRole policy. It provides the permissions for your service role to:
1. Read the tags on your instances or identify your Amazon EC2 instances by Amazon EC2 Auto Scaling group names.
2. Read, create, update, and delete Amazon EC2 Auto Scaling groups, lifecycle hooks, and scaling policies.
3. Publish information to Amazon SNS topics.
4. Retrieve information about CloudWatch alarms.
5. Read and update Elastic Load Balancing.
EOT
}

variable infra_env {
  type        = string
  description = "name of the environment (develop || production || etc)"
}
