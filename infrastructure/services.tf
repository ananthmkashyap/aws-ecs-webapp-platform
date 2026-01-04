resource "aws_ecs_service" "frontend_service" {
    name = "${local.name}-frontend-service"
    cluster = aws_ecs_cluster.ecs_webapp.id
    task_definition = "frontend:1"
    desired_count = 3
    iam_role = aws_iam_role.ecs_service_role.arn

    lifecycle {
      ignore_changes = [task_definition]
    }

    deployment_controller {
      type = "CODE_DEPLOY"
    }

    deployment_configuration {
      strategy = "BLUE_GREEN"
      bake_time_in_minutes = 5
    }

    load_balancer {
      container_name = "frontend"
      container_port = 3000
      target_group_arn = module.alb.target_groups.ecs_webapp_arn
      advanced_configuration {
        alternate_target_group_arn = module.alb.target_groups.ecs_webapp_alt_arn
        production_listener_rule = module.alb.listeners.https_rule_arn
        role_arn = aws_iam_role.ecs_service_role.arn
      }
    }  

    network_configuration {
      security_groups = aws_security_group.allow_https.id
      subnets = module.vpc.private_subnets
    }

    service_connect_configuration {
      enabled = true
    }
}

resource "aws_ecs_service" "backend_service" {
    name = "${local.name}-backend-service"
    cluster = aws_ecs_cluster.ecs_webapp.id
    task_definition = "backend:1"
    desired_count = 3
    iam_role = aws_iam_role.ecs_service_role.arn

    lifecycle {
      ignore_changes = [task_definition]
    }

    deployment_controller {
      type = "ECS"
    }

    deployment_configuration {
      strategy = "ROLLING"
    } 

    network_configuration {
      security_groups = aws_security_group.allow_https.id
      subnets = module.vpc.private_subnets
    }

    service_connect_configuration {
        enabled = true

        service {
            port_name      = "http"
            discovery_name = "backend"

            client_alias {
            dns_name = "backend"
            port     = 8000
            }
        }
    }
}

resource "aws_iam_role" "ecs_service_role" {
  name = "${local.name}-ecs-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com",
            "ecs.amazonaws.com",
          ]
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_service_role" {
  role       = aws_iam_role.ecs_service_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "ecs_alb_management_role" {
  role       = aws_iam_role.ecs_service_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}