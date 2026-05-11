module "service" {
  source = "git@github.com:trade-tariff/trade-tariff-platform-terraform-modules.git//aws/ecs-service?ref=aws/ecs-service-v3.0.1"

  region = var.region

  service_name  = "admin"
  service_count = var.service_count

  cluster_name    = "trade-tariff-cluster-${var.environment}"
  subnet_ids      = data.aws_subnets.private.ids
  security_groups = [data.aws_security_group.this.id]

  target_group_arn = data.aws_lb_target_group.this_https.arn
  container_port   = 8443

  cloudwatch_log_group_name = "platform-logs-${var.environment}"

  min_capacity        = var.min_capacity
  max_capacity        = var.max_capacity
  autoscaling_metrics = var.autoscaling_metrics

  docker_image = local.ecr_repo
  docker_tag   = var.docker_tag
  skip_destroy = true

  cpu                 = var.cpu
  memory              = var.memory
  enable_alarms       = var.enable_alarms
  cpu_alarm_threshold = 75

  task_role_policy_arns = [aws_iam_policy.task.arn]
  enable_ecs_exec       = true

  service_environment_config = local.admin_service_env_vars

  sns_topic_arns = [data.aws_sns_topic.slack_topic.arn]
}
