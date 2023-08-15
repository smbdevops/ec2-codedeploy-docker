variable "project_name" {
  type    = string
  default = "com.example.app"
}

variable "infra_env" {
  type    = string
  default = "develop"
}

variable "subnets" {
  type = list(string)
  default = ["subnet-028099023b1399a70", "subnet-0d083abbe1d0c8981"]
}

variable "vpc_id" {
  type = string
  default = "vpc-21804746"
}

variable "certificate_arn" {
  type = string
  default = "arn:aws:acm:us-west-1:848116219031:certificate/e0214745-b6f5-45fe-b4ec-2cf029fb12a6"
}