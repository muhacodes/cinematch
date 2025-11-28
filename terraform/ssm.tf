# AWS Systems Manager Parameter Store - Secure secrets storage
# These parameters will be encrypted and accessed by EC2 and GitHub Actions

resource "aws_ssm_parameter" "django_secret_key" {
  name        = "/${var.project_name}/${var.environment}/django-secret-key"
  description = "Django SECRET_KEY"
  type        = "SecureString"
  value       = var.django_secret_key

  tags = {
    Name = "${var.project_name}-django-secret"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/${var.environment}/db-password"
  description = "RDS PostgreSQL password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_ssm_parameter" "db_host" {
  name        = "/${var.project_name}/${var.environment}/db-host"
  description = "RDS PostgreSQL host"
  type        = "String"
  value       = aws_db_instance.postgres.address

  tags = {
    Name = "${var.project_name}-db-host"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project_name}/${var.environment}/db-name"
  description = "RDS PostgreSQL database name"
  type        = "String"
  value       = var.db_name

  tags = {
    Name = "${var.project_name}-db-name"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/db-username"
  description = "RDS PostgreSQL username"
  type        = "String"
  value       = var.db_username

  tags = {
    Name = "${var.project_name}-db-username"
  }
}

resource "aws_ssm_parameter" "tmdb_token" {
  name        = "/${var.project_name}/${var.environment}/tmdb-token"
  description = "TMDB API Read Access Token"
  type        = "SecureString"
  value       = var.tmdb_token

  tags = {
    Name = "${var.project_name}-tmdb-token"
  }
}

resource "aws_ssm_parameter" "llm_api_key" {
  name        = "/${var.project_name}/${var.environment}/llm-api-key"
  description = "LLM API Key"
  type        = "SecureString"
  value       = var.llm_api_key

  tags = {
    Name = "${var.project_name}-llm-api-key"
  }
}

resource "aws_ssm_parameter" "dockerhub_image" {
  name        = "/${var.project_name}/${var.environment}/dockerhub-image"
  description = "DockerHub image name"
  type        = "String"
  value       = var.dockerhub_image

  tags = {
    Name = "${var.project_name}-dockerhub-image"
  }
}

resource "aws_ssm_parameter" "domain_name" {
  name        = "/${var.project_name}/${var.environment}/domain-name"
  description = "Domain name for the application"
  type        = "String"
  value       = var.domain_name

  tags = {
    Name = "${var.project_name}-domain-name"
  }
}

# SSH key for GitHub Actions (optional - only if you want SSH fallback)
# You need to manually create this parameter with your private key:
# aws ssm put-parameter --name "/cinematch/production/ec2-ssh-key" --value "$(cat ~/.ssh/your-key.pem)" --type "SecureString"
# This is just a placeholder to document the parameter
resource "aws_ssm_parameter" "ec2_ssh_key" {
  name        = "/${var.project_name}/${var.environment}/ec2-ssh-key"
  description = "EC2 SSH private key for GitHub Actions (optional)"
  type        = "SecureString"
  value       = "placeholder-update-manually"
  overwrite   = true

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-ec2-ssh-key"
  }
}

