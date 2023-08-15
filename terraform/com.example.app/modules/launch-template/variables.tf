variable project_name {
  type        = string
  description = "used for prefixing or naming resources"
}

variable ami_name {
  type        = string
  description = "Name key to search for"
}

variable instance_profile_arn {
  type        = string
  description = "Instance Profile with sufficient privileges to Query for and allocate an EIP"
}

variable security_group_id {
  type        = string
  description = "Security Group for the EC2 Instance(s) when launched."
}


variable user_data_script_path {
  type        = string
  description = "path to user data script"
}