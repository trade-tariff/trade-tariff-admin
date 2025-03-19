module "service" {
  source = "git@github.com:trade-tariff/trade-tariff-platform-terraform-modules.git//aws/ecs-service?ref=aws/ecs-service-v1.12.0"

  region = var.region

  service_name  = local.service
  service_count = var.service_count

  cluster_name              = "trade-tariff-cluster-${var.environment}"
  subnet_ids                = data.aws_subnets.private.ids
  security_groups           = [data.aws_security_group.this.id]
  target_group_arn          = data.aws_lb_target_group.this.arn
  cloudwatch_log_group_name = "platform-logs-${var.environment}"

  min_capacity = var.min_capacity
  max_capacity = var.max_capacity

  docker_image = "382373577178.dkr.ecr.eu-west-2.amazonaws.com/tariff-admin-production"
  docker_tag   = var.docker_tag
  skip_destroy = true

  container_port = 8080

  cpu    = var.cpu
  memory = var.memory

  task_role_policy_arns = [
    aws_iam_policy.exec.arn
  ]

  execution_role_policy_arns = [
    aws_iam_policy.secrets.arn
  ]

  enable_ecs_exec = true

  init_container            = true
  init_container_entrypoint = [""]
  init_container_command    = ["/bin/sh", "-c", "bundle exec rails db:migrate"]

  service_environment_config = [
    {
      name  = "PORT"
      value = "8080"
    },
    {
      name  = "API_SERVICE_BACKEND_URL_OPTIONS"
      value = jsonencode(local.api_service_backend_url_options)
    },
    {
      name  = "GDS_SSO_STRATEGY"
      value = "real"
    },
    {
      name  = "GOVUK_APP_DOMAIN"
      value = "admin.${var.base_domain}"
    },
    {
      name  = "GOVUK_FRONTEND"
      value = "true"
    },
    {
      name  = "GOVUK_WEBSITE_ROOT"
      value = "https://www.gov.uk"
    },
    {
      name  = "MAX_THREADS"
      value = "16"
    },
    {
      name  = "PLEK_SERVICE_SIGNON_URI"
      value = local.signon_url
    },
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "PLEK_SERVICE_TARIFF_API_URI"
      value = "http://backend-uk.tariff.internal:8080"
    },
    {
      name  = "WEB_CONCURRENCY"
      value = "1"
    }
  ]

  service_secrets_config = [
    {
      name      = "DATABASE_URL"
      valueFrom = data.aws_secretsmanager_secret.postgres.arn
    },
    {
      name      = "BEARER_TOKEN"
      valueFrom = data.aws_secretsmanager_secret.admin_bearer_token.arn
    },
    {
      name      = "SECRET_KEY_BASE"
      valueFrom = data.aws_secretsmanager_secret.admin_secret_key_base.arn
    },
    {
      name      = "TARIFF_ADMIN_OAUTH_ID"
      valueFrom = data.aws_secretsmanager_secret.admin_oauth_id.arn
    },
    {
      name      = "TARIFF_ADMIN_OAUTH_SECRET"
      valueFrom = data.aws_secretsmanager_secret.admin_oauth_secret.arn
    },
    {
      name      = "SENTRY_DSN"
      valueFrom = data.aws_secretsmanager_secret.sentry_dsn.arn
    },
  ]
}
