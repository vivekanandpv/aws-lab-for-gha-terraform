resource "aws_ssm_document" "student_deploy" {
  for_each = var.students

  name            = "${var.project_name}-deploy-${each.key}"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy ${each.key} application to Grand Calvin"
    parameters = {
      ImageUri = {
        type              = "String"
        description       = "ECR image URI for ${each.key}"
        interpolationType = "ENV_VAR"
        allowedPattern    = "^[0-9]{12}\\.dkr\\.ecr\\.${var.aws_region}\\.amazonaws\\.com/training/${each.key}:[A-Za-z0-9._-]+$"
      }

      StudentId = {
        type              = "String"
        description       = "Student identifier supplied by the learner repository"
        interpolationType = "ENV_VAR"
        allowedPattern    = "^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$"
      }
    }
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "deploy${replace(each.key, "-", "")}"
      precondition = {
        StringEquals = ["platformType", "Linux"]
      }
      inputs = {
        timeoutSeconds = "300"
        runCommand = [
          "set -euo pipefail",
          "if [ -z \"$${SSM_ImageUri+x}\" ]; then export SSM_ImageUri='{{ImageUri}}'; fi",
          "if [ -z \"$${SSM_StudentId+x}\" ]; then export SSM_StudentId='{{StudentId}}'; fi",
          "/opt/calvin/bin/deploy-student '${each.key}' \"$SSM_ImageUri\" '${each.value.port}' \"$SSM_StudentId\""
        ]
      }
    }]
  })

  tags = merge(local.common_tags, {
    Student = each.key
  })
}
