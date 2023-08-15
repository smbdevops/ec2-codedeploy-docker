provider "aws" {
  region                   = var.aws_region
  profile                  = "example"
  shared_credentials_files = [
    "~/.aws/credentials",
    "/.aws/credentials"
  ]
}