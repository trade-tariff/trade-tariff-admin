data "aws_iam_policy_document" "task" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  # Distribution lists: manage membership of dl-* groups in the identity user
  # pool. IAM cannot restrict by group name, so the app only allows dl-* groups.
  # AdminListGroupsForUser and AdminDeleteUser let admin delete a user when an
  # unsubscribe removes them from their last group. Only added when
  # COGNITO_USER_POOL_ID is set.
  dynamic "statement" {
    for_each = data.aws_cognito_user_pool.identity

    content {
      effect = "Allow"
      actions = [
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminDeleteUser",
        "cognito-idp:AdminGetUser",
        "cognito-idp:AdminListGroupsForUser",
        "cognito-idp:AdminRemoveUserFromGroup",
        "cognito-idp:ListGroups",
        "cognito-idp:ListUsersInGroup",
      ]
      resources = [statement.value.arn]
    }
  }
}

resource "aws_iam_policy" "task" {
  name   = "admin-task-role-policy"
  policy = data.aws_iam_policy_document.task.json
}
