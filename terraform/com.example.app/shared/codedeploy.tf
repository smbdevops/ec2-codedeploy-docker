resource "aws_codedeploy_app" "app" {
  name = var.project_name
}

resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = "${var.project_name}-codedeploy"
  tags   = {
    Name        = "${var.project_name}-codedeploy"
    Environment = "shared"
  }
}