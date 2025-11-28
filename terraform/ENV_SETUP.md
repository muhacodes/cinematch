# Environment Variables Setup for Terraform

## Overview

Terraform can load variables from environment variables prefixed with `TF_VAR_`. This allows you to keep secrets in a `.env` file that's not committed to git.

## Setup Instructions

### 1. Create your `.env` file

```bash
cd terraform
cp terraform.tfvars.example .env
```

### 2. Edit `.env` and add the `TF_VAR_` prefix to each variable

```bash
# Terraform Variables - Keep this file secure and never commit it!

# AWS Configuration
TF_VAR_aws_region=us-east-1
TF_VAR_environment=production
TF_VAR_project_name=cinematch

# Domain Configuration
TF_VAR_domain_name=api.cinematch.muhacodes.com

# Database Configuration
TF_VAR_db_name=cinematch
TF_VAR_db_username=cinematch_admin
TF_VAR_db_password=your-strong-password-here

# EC2 Configuration
TF_VAR_ec2_instance_type=t2.micro
TF_VAR_ec2_key_name=your-ec2-key-pair-name

# DockerHub
TF_VAR_dockerhub_image=yourusername/cinematch:latest

# API Keys (Keep these secret!)
TF_VAR_tmdb_token=your-tmdb-read-access-token
TF_VAR_llm_api_key=your-llm-api-key
TF_VAR_django_secret_key=your-django-secret-key
```

### 3. Load environment variables

```bash
# Load variables into your shell
source ./load-env.sh

# Or manually:
set -a
source .env
set +a
```

### 4. Run Terraform

```bash
terraform init
terraform plan
terraform apply
```

## Security Notes

- ✅ **DO**: Keep `.env` in `.gitignore`
- ✅ **DO**: Use strong passwords and rotate them regularly
- ✅ **DO**: Use AWS SSM Parameter Store for runtime secrets
- ❌ **DON'T**: Commit `.env` to git
- ❌ **DON'T**: Share `.env` file or its contents
- ❌ **DON'T**: Hardcode secrets in Terraform files

## How It Works

1. **Development/Local**: Terraform reads `TF_VAR_*` environment variables from your shell
2. **EC2 Runtime**: Secrets are fetched from AWS SSM Parameter Store (encrypted)
3. **GitHub Actions**: Uses AWS SSM Parameter Store and IAM roles

No secrets are exposed in:
- Terraform state files (uses variable references)
- EC2 user data (fetches from SSM at runtime)
- GitHub repository (uses AWS SSM)

