variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile Terraform should use"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cinematch"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Free tier eligible
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "cinematch"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "cinematch_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Cheapest option
}

variable "ec2_key_name" {
  type = string
  description = "EC2 key pair name for SSH"
}

variable "dockerhub_image" {
  description = "DockerHub image name"
  type        = string
  default     = "yourusername/cinematch:latest"
}

variable "domain_name" {
  description = "Domain name for the API"
  type        = string
  default     = "api.cinematch.muhacodes.com"
}

variable "tmdb_token" {
  description = "TMDB API Read Access Token"
  type        = string
  sensitive   = true
}

variable "llm_api_key" {
  description = "LLM API Key"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
}

