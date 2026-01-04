locals {
  azs = ["eu-central-1a","eu-central-1b","eu-central-1c"]
  name = "ecs-webapp"
  vpc_cidr = "10.0.0.0/16"
  container_port = 3000
}