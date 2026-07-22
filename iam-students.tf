data "aws_iam_policy_document" "student_oidc_trust" {
  for_each = var.students

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_owner}@*/${each.value.github_repository}@*:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "student_deployer" {
  for_each = var.students

  name               = "${var.project_name}-${each.key}-deployer"
  assume_role_policy = data.aws_iam_policy_document.student_oidc_trust[each.key].json

  tags = merge(local.common_tags, {
    Student = each.key
  })
}

data "aws_iam_policy_document" "student_deployer" {
  for_each = var.students

  statement {
    sid       = "GetEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushOnlyOwnRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.student[each.key].arn]
  }

  statement {
    sid     = "InvokeOwnDeploymentDocumentOnCalvin"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]
    resources = [
      aws_ssm_document.student_deploy[each.key].arn,
      aws_instance.calvin.arn
    ]
  }

  statement {
    sid    = "ReadCommandResult"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "student_deployer" {
  for_each = var.students

  name   = "${var.project_name}-${each.key}-deployment"
  role   = aws_iam_role.student_deployer[each.key].id
  policy = data.aws_iam_policy_document.student_deployer[each.key].json
}
