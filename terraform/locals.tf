locals {
  secret_value = try(data.aws_secretsmanager_secret_version.this.secret_string, "{}")
  secret_map   = jsondecode(local.secret_value)
  secret_env_vars = [
    for key, value in local.secret_map : {
      name  = key
      value = value
    }
  ]

  ecr_repo = "382373577178.dkr.ecr.eu-west-2.amazonaws.com/tariff-admin-production"

  database_env_vars = [
    {
      name  = "DATABASE_URL"
      value = data.aws_secretsmanager_secret_version.database_url.secret_string
    }
  ]

  sidekiq_env_vars = [
    {
      name  = "SIDEKIQ_UK_REDIS_URL"
      value = data.aws_secretsmanager_secret_version.sidekiq_uk_redis_url.secret_string
    },
    {
      name  = "SIDEKIQ_XI_REDIS_URL"
      value = data.aws_secretsmanager_secret_version.sidekiq_xi_redis_url.secret_string
    }
  ]

  tls_secret = jsondecode(data.aws_secretsmanager_secret_version.ecs_tls_certificate.secret_string)

  ecs_tls_env_vars = [
    {
      name  = "SSL_KEY_PEM"
      value = local.tls_secret.private_key
    },
    {
      name  = "SSL_CERT_PEM"
      value = local.tls_secret.certificate
    },
    {
      name  = "SSL_PORT"
      value = "8443"
    }
  ]

  admin_service_env_vars = concat(local.secret_env_vars, local.database_env_vars, local.sidekiq_env_vars, local.ecs_tls_env_vars)

  # Paths the image must still be able to write to under a read-only root filesystem.
  # WORKDIR is /app, so Rails.root-relative paths resolve there.
  #   /tmp      - ClientBuilder writes the backend TLS cert to /tmp/backend.crt
  #   /app/tmp  - bootsnap, loaded in config/boot.rb; without it the app fails to boot
  #   /app/log  - Rails log directory; logs go to stdout, kept for parity with other services
  writable_paths = ["/tmp", "/app/tmp", "/app/log"]

  # Matches the uid/gid pinned in the Dockerfile. The ecs-service module adds an init
  # container that chowns the writable mounts to this user, because Fargate mounts them
  # root-owned and the app runs as the non-root `tariff`.
  container_user = "1000:1000"
}
