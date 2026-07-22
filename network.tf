resource "aws_vpc" "calvin" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "calvin" {
  vpc_id = aws_vpc.calvin.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.calvin.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.calvin.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.calvin.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "calvin" {
  name_prefix = "${var.project_name}-"
  description = "Public access to assigned student application ports; no SSH"
  vpc_id      = aws_vpc.calvin.id

  dynamic "ingress" {
    for_each = toset(var.allowed_app_cidrs)
    content {
      description = "Student apps from ${ingress.value}"
      from_port   = 8101
      to_port     = 8130
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Outbound access for SSM, ECR and package installation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "calvin" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eip"
  })
}

resource "aws_eip_association" "calvin" {
  allocation_id = aws_eip.calvin.id
  instance_id   = aws_instance.calvin.id
}
