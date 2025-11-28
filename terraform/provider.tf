provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "CineMatch"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}