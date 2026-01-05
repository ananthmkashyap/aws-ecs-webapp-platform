resource "aws_ecs_cluster" "ecs_webapp" {
  name = "ecs_webapp"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_webapp.name

  capacity_providers = ["${aws_ecs_capacity_provider.ecs_managed_capacity_provider.name}"]
  
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "${aws_ecs_capacity_provider.ecs_managed_capacity_provider.name}"
  }
}

resource "aws_ecs_capacity_provider" "ecs_managed_capacity_provider" {
  name    = "ecs_managed_capacity_provider"
  cluster = aws_ecs_cluster.ecs_webapp.name

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.ecs_infra_role.arn
    propagate_tags          = "CAPACITY_PROVIDER"

    instance_launch_template {
      ec2_instance_profile_arn = aws_iam_instance_profile.ecs_managed_instance_profile.arn
      monitoring               = "ENABLED"

      network_configuration {
        subnets         = module.vpc.private_subnets
      }

      storage_configuration {
        storage_size_gib = 5
      }

      instance_requirements {
        memory_mib {
          min = 1024
          max = 8192
        }

        vcpu_count {
          min = 1
          max = 4
        }

        instance_generations = ["current"]
        cpu_manufacturers    = ["intel", "amd"]
      }
    }
  }
}

resource "aws_iam_instance_profile" "ecs_managed_instance_profile" {
  name = "ecs_managed_instance_profile"
  role = aws_iam_role.ecs_infra_role.name
}

resource "aws_iam_role" "ecs_infra_role" {
  name = "${local.name}-infra"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = [
        "ecs.amazonaws.com",
        "ec2.amazonaws.com"
      ] }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_managed_ec2" {
  role       = aws_iam_role.ecs_infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${local.name}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "${local.name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ssm_parameter" "secrets" {
  for_each = local.secrets

  name      = each.key
  type      = "SecureString"
  value     = each.value
  overwrite = true
}

resource "aws_db_instance" "ecs_webapp_db" {
  allocated_storage           = 16
  max_allocated_storage       = 100 
  db_name                     = "ecs_webapp_db"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.xlarge"
  manage_master_user_password = true
  username                    = "ecs_webapp_admin"
  multi_az                    = true
}