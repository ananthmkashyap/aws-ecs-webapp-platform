resource "aws_iam_openid_connect_provider" "github_oidc" {   
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"] 
}

resource "aws_iam_role" "github_actions_deploy_role" {
  name = "gha-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:allocnow/ecs_frontend:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_access_attachment" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "code_deploy_access_attachment" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployDeployerAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_access_attachment" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role" "github_actions_terraform_role" {
  name = "gha-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:allocnow/webapp_*:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.github_actions_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

