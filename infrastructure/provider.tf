provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "ecs-terraform-state"
    key = "ecs-terraform-state/terraform.tfstate"
    region = "eu-central-1"
    use_lockfile = true
  }
}