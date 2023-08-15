terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
  backend "s3" {
    shared_credentials_file = "/.aws/credentials"
    region                  = "us-west-1"
    profile                 = "default"
  }
}
