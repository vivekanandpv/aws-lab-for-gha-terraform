resource "aws_instance" "calvin" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.calvin.id]
  iam_instance_profile        = aws_iam_instance_profile.calvin.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/calvin-user-data.sh.tftpl", {
    aws_region = var.aws_region
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gib
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = var.project_name
    Role = "shared-docker-host"
  })

  depends_on = [
    aws_iam_role_policy_attachment.calvin_ssm,
    aws_iam_role_policy.calvin_ecr_pull,
    aws_route_table_association.public
  ]
}
