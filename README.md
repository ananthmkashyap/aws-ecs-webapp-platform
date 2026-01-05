# aws-ecs-webapp-platform

### IAM Roles
1. ecs_infra_role 
->  It is passed to the managed_instances_provider so the ECS service can scale your infrastructure (ASG) up and down.
->  It is wrapped in an aws_iam_instance_profile and assigned to the EC2 instances. This allows the ECS Agent on the server to register the node to the cluster and stream logs.

2. ecsTaskExecutionRole -> Used by ECS Agent to pull imges from ecr, stream logs to Cloudwatch and read secrets from ssm

3. ecsTaskRole -> Used by tasks to communicate to other AWS services.

4. codedeploy-service-role -> Used by code deploy to manage listeners in ALB for traffic switching.

### Cost estimates

1. AWS -> (file:///C:/Users/Admin/Desktop/aws_cost_estimation.pdf)
2. GitHub -> (https://docs.google.com/spreadsheets/d/1Uij-L3VSlfvifVA-1E-It5lj5HQ2EEVy9fI1q_Qtfvc/edit?gid=1077186799#gid=1077186799)