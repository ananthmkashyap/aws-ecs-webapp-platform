resource "aws_codedeploy_app" "ecs_webapp_codedeploy_app" {
  compute_platform = "ECS"
  name             = "${local.name}-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "codedeploy_frontend_group" {
  app_name               = aws_codedeploy_app.ecs_webapp_codedeploy_app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${local.name}-codedeploy-frontend-group"
  service_role_arn       = aws_iam_role.ecs_service_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_webapp.name
    service_name = aws_ecs_service.frontend_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [module.alb.listeners.https_arn]
      }

      target_group {
        name = module.alb.target_groups.ecs_webapp.name
      }

      target_group {
        name = module.alb.target_groups.ecs_webapp_alt.name
      }
    }
  }
}

resource "aws_codedeploy_deployment_group" "codedeploy_backend_group" {
  app_name               = aws_codedeploy_app.ecs_webapp_codedeploy_app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${local.name}-codedeploy-backend-group"
  service_role_arn       = aws_iam_role.ecs_service_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_webapp.name
    service_name = aws_ecs_service.backend_service.name
  }
}