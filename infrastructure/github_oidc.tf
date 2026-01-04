resource "aws_iam_openid_connect_provider" "github_oidc" {   
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"] 
}

resource "aws_iam_role" "github_actions_oidc_role" {
  name = "GhaOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRole"
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

data "aws_iam_policy" "ecr_access" {
  arn = "arn:aws:iam::123456789012:policy/UsersManageOwnCredentials"
}

resource "aws_iam_role_policy_attachment" "ecr_access_attachment" {
  role       = aws_iam_role.github_actions_oidc_role.name
  policy_arn = data.aws_iam_policy.ecr_access.arn
}