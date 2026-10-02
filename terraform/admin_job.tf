module "admin-job" {
  source = "git@github.com:trade-tariff/trade-tariff-platform-terraform-modules.git//aws/ecs-service?ref=aws/ecs-service-v3.3.1"

  region = var.region

  service_name              = "admin-job"
  container_definition_kind = "job"
  container_command         = ["/bin/sh", "-C", "bin/null-service"]
  service_count             = 0

  cluster_name              = "trade-tariff-cluster-${var.environment}"
  subnet_ids                = data.aws_subnets.private.ids
  security_groups           = [data.aws_security_group.this.id]
  cloudwatch_log_group_name = "platform-logs-${var.environment}"

  docker_image = local.ecr_repo
  docker_tag   = var.docker_tag
  cpu          = var.cpu
  memory       = var.memory

  task_role_policy_arns = [aws_iam_policy.task.arn]

  service_environment_config = local.admin_service_env_vars

  enable_ecs_exec = true

  # WORKDIR is /app, so Rails.root-relative paths resolve there.
  #   /tmp      - ClientBuilder writes the backend TLS cert to /tmp/backend.crt
  #   /app/tmp  - bootsnap, loaded in config/boot.rb; without it the app fails to boot
  #   /app/log  - Rails log directory
  # container_user matches the uid/gid pinned in the Dockerfile; the module's init
  # container chowns the writable mounts to it so the non-root process can write to them.
  readonly_root_filesystem = true
  writable_paths           = ["/tmp", "/app/tmp", "/app/log"]
  container_user           = "1000:1000"

  has_autoscaler = false
  max_capacity   = 1
  min_capacity   = 0
  enable_alarms  = false

  sns_topic_arns = [data.aws_sns_topic.slack_topic.arn]
}
