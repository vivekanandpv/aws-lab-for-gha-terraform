output "calvin_instance_id" {
  description = "EC2 instance ID used by GitHub Actions SSM commands."
  value       = aws_instance.calvin.id
}

output "calvin_public_ip" {
  description = "Stable Elastic IP of Grand Calvin."
  value       = aws_eip.calvin.public_ip
}

output "student_configuration" {
  description = "Values to place in each learner repository workflow."
  value = {
    for id, student in var.students : id => {
      github_repository     = student.github_repository
      github_repository_url = "https://github.com/${var.github_owner}/${student.github_repository}"
      role_arn              = aws_iam_role.student_deployer[id].arn
      ecr_repository        = aws_ecr_repository.student[id].name
      ecr_repository_url    = aws_ecr_repository.student[id].repository_url
      ssm_document          = aws_ssm_document.student_deploy[id].name
      instance_id           = aws_instance.calvin.id
      port                  = student.port
      application_url       = "http://${aws_eip.calvin.public_ip}:${student.port}"
    }
  }
}

output "aws_region" {
  description = "AWS region used by the lab."
  value       = var.aws_region
}
