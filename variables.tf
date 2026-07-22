variable "aws_region" {
  description = "AWS Region in which the lab is created."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for names and tags."
  type        = string
  default     = "grand-calvin"
}

variable "vpc_cidr" {
  description = "CIDR block for the Calvin VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.40.1.0/24"
}

variable "allowed_app_cidrs" {
  description = "IPv4 CIDRs allowed to reach student application ports. Prefer the training venue's public IP /32."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "Grand Calvin EC2 instance type."
  type        = string
  default     = "m7i.2xlarge"
}

variable "root_volume_size_gib" {
  description = "Calvin root EBS volume size in GiB."
  type        = number
  default     = 100
}

variable "github_owner" {
  description = "GitHub organisation or username that owns all learner repositories."
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume each learner deployment role."
  type        = string
  default     = "main"
}

variable "create_github_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider. Set false when it already exists."
  type        = bool
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN when create_github_oidc_provider is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_github_oidc_provider || var.existing_github_oidc_provider_arn != null
    error_message = "existing_github_oidc_provider_arn must be set when create_github_oidc_provider is false."
  }
}

variable "students" {
  description = "Learner allocation. Map key becomes the student ID."
  type = map(object({
    github_repository = string
    port              = number
  }))

  validation {
    condition = alltrue([
      for id, student in var.students :
      can(regex("^student([0-2][0-9]|30)$", id)) &&
      student.port >= 8101 && student.port <= 8130
    ])
    error_message = "Student IDs must be student01..student30 and ports must be 8101..8130."
  }

  validation {
    condition     = length(distinct([for student in values(var.students) : student.port])) == length(var.students)
    error_message = "Every student must have a unique host port."
  }
}
