locals {
  secret_value = try(data.aws_secretsmanager_secret_version.this.secret_string, "{}")
  secret_map   = jsondecode(local.secret_value)
  secret_env_vars = [
    for key, value in local.secret_map : {
      name  = key
      value = value
    }
  ]

  database_env_vars = [
    {
      name  = "DATABASE_URL"
      value = data.aws_secretsmanager_secret_version.database_url.secret_string
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

  admin_service_env_vars = concat(local.secret_env_vars, local.database_env_vars, local.ecs_tls_env_vars)
}
