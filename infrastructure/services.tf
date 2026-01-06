locals {
  services_to_scale = {
    "${aws_ecs_service.frontend_service.name}" = {
      min            = 3
      max            = 10
      cpu_target     = 80
    }
    "${aws_ecs_service.backend_service.name}" = {
      min            = 3
      max            = 10
      cpu_target     = 80
    }
  }
}

resource "aws_ecs_service" "frontend_service" {
    name = "${local.name}-frontend-service"
    cluster = aws_ecs_cluster.ecs_webapp.id
    task_definition = "frontend:1"
    desired_count = 3

    lifecycle {
      ignore_changes = [task_definition, desired_count]
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
      security_groups = [aws_security_group.allow_https.id]
      subnets = module.vpc.private_subnets
    }

    service_connect_configuration {
      enabled   = true
      service {
        port_name      = "frontend-port"
        discovery_name = "frontend"
        client_alias {
          dns_name = "frontend"
          port     = 3000
        }
      }
    }
}

resource "aws_appautoscaling_target" "ecs_target" {
  for_each = local.services_to_scale
  max_capacity       = each.value.max
  min_capacity       = each.value.min
  resource_id        = "service/${aws_ecs_cluster.ecs_webapp.name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policies" {
  for_each           = local.services_to_scale
  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = each.value.cpu_target
  }
}

resource "aws_ecs_service" "backend_service" {
    name = "${local.name}-backend-service"
    cluster = aws_ecs_cluster.ecs_webapp.id
    task_definition = "backend:1"
    desired_count = 3

    lifecycle {
      ignore_changes = [task_definition, desired_count]
    }

    deployment_controller {
      type = "ECS"
    }

    deployment_configuration {
      strategy = "ROLLING"
    } 

    network_configuration {
      security_groups = [aws_security_group.allow_https.id]
      subnets = module.vpc.private_subnets
    }

    service_connect_configuration {
        enabled = true

        service {
            port_name      = "backend-port"
            discovery_name = "backend"

            client_alias {
            dns_name = "backend"
            port     = 5000
            }
        }
    }
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = "${local.name}-codedeploy-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
        Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "codedeploy_service_role" {
  role       = aws_iam_role.codedeploy_service_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
}