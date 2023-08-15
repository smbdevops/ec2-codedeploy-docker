data "aws_ami" "example" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:tested"
    values = ["true"]
  }

  ## owners = ["848116219031"] # Canonical
}


resource "aws_launch_template" "ec2_with_docker_and_codedpeloy" {
  name = var.project_name
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    arn = var.instance_profile_arn
  }
  image_id                             = data.aws_ami.example.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_requirements {
    memory_mib {
      min = 1024
    }
    vcpu_count {
      min = 1
    }
    allowed_instance_types = [
      "c5*.*", "c6*.*", "t3*.*"
    ]
  }
  key_name = "root_key_pair"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }


  vpc_security_group_ids = [var.security_group_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.project_name
    }
  }
}