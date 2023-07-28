data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.aws_secretsmanager_secret.admin_secret_key_base.arn,
      data.aws_secretsmanager_secret.admin_bearer_token.arn,
      data.aws_secretsmanager_secret.admin_oauth_id.arn,
      data.aws_secretsmanager_secret.admin_oauth_secret.arn,
      data.aws_secretsmanager_secret.redis.arn,
      data.aws_secretsmanager_secret.newrelic_license_key.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlainText",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = [
      data.aws_kms_key.secretsmanager_key.arn
    ]
  }
}

resource "aws_iam_policy" "secrets" {
  name   = "${local.service}-execution-role-secrets-policy"
  policy = data.aws_iam_policy_document.secrets.json
}

data "aws_iam_policy_document" "exec" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "exec" {
  name   = "${local.service}-task-role-exec-policy"
  policy = data.aws_iam_policy_document.exec.json
}