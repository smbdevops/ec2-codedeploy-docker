packer {
  required_plugins {
    docker = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  ami_name = "ubuntu-codedeploy-docker-${formatdate("YYYY-MM-DD-hhmmss", timestamp())}"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = local.ami_name
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami = "ami-016d1b215ea28dcee"
  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    script = "install.sh"
  }
}
