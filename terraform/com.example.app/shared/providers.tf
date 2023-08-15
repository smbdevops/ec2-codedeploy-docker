provider "aws" {
  region                   = "us-west-1"
  profile                  = "default"
  shared_credentials_files = [
    "~/.aws/credentials",
    "/.aws/credentials"
  ]
}