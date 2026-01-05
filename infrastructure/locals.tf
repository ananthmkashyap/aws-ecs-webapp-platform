locals {
  azs = ["eu-central-1a","eu-central-1b","eu-central-1c"]
  name = "ecs-webapp"
  vpc_cidr = "10.0.0.0/16"
  container_port = 3000

  secrets = {
    "rds_password" = var.rds_password
    "api_key"      = var.api_key
  }
}

variable "api_key" {
  type = string
  sensitive = true
}

variable "rds_password" {
  type = string
  sensitive = true
}