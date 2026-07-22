locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  common_tags = {
    Environment = "training"
  }

  ecr_repository_names = {
    for id, student in var.students : id => "training/${id}"
  }

  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
}
