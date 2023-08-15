variable aws_region {
  type        = string
  description = "AWS Region to build resources in"
  default     = "us-west-1"
}

variable project_name {
  type        = string
  description = "used for prefixing resources"
  default     = "com.example.app"
}

variable "aws_route_53_zone_id" {
  type        = string
  description = "The Zone ID to place the SSL certificate validation CNAME values into"
}
