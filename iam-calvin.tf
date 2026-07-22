data "aws_iam_policy_document" "calvin_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "calvin" {
  name               = "${var.project_name}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.calvin_assume_role.json
}

resource "aws_iam_role_policy_attachment" "calvin_ssm" {
  role       = aws_iam_role.calvin.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "calvin_ecr_pull" {
  statement {
    sid       = "GetEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PullStudentImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [for repository in aws_ecr_repository.student : repository.arn]
  }
}

resource "aws_iam_role_policy" "calvin_ecr_pull" {
  name   = "${var.project_name}-ecr-pull"
  role   = aws_iam_role.calvin.id
  policy = data.aws_iam_policy_document.calvin_ecr_pull.json
}

resource "aws_iam_instance_profile" "calvin" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.calvin.name
}
