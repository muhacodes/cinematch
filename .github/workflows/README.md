# CI/CD Pipeline

This directory contains GitHub Actions workflows for automated testing and deployment.

## Workflows

### 1. `test.yml` - Run Tests
Runs on every push and pull request to main/master branches.
- Sets up Python environment
- Installs dependencies
- Runs linting (flake8)
- Runs Django tests
- Checks for pending migrations

### 2. `deploy.yml` - Build and Deploy
Runs on push to main/master branches.

**Jobs:**
1. **build-and-push**: Builds Docker image and pushes to DockerHub
2. **deploy**: Deploys to AWS EC2 instance
3. **notify**: Sends deployment status notification

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings (Settings > Secrets and variables > Actions):

### DockerHub Secrets
- `DOCKERHUB_USERNAME`: Your DockerHub username
- `DOCKERHUB_TOKEN`: DockerHub access token (create at https://hub.docker.com/settings/security)

### AWS Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `EC2_HOST`: EC2 public IP or DNS
- `EC2_SSH_PRIVATE_KEY`: Private key content for SSH access to EC2

## Setup Instructions

### 1. DockerHub Setup
```bash
# Login to DockerHub
docker login

# Create access token at https://hub.docker.com/settings/security
# Add DOCKERHUB_USERNAME and DOCKERHUB_TOKEN to GitHub secrets
```

### 2. AWS Setup
```bash
# Create IAM user with EC2 access
# Get access key and secret key
# Add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to GitHub secrets

# Get EC2 public IP from Terraform output
terraform output ec2_public_ip

# Add EC2_HOST to GitHub secrets
# Add your EC2 private key content to EC2_SSH_PRIVATE_KEY secret
```

### 3. Trigger Deployment
```bash
# Push to main/master branch
git push origin main

# Or manually trigger from GitHub Actions tab
```

## Docker Image Tagging

The pipeline creates multiple tags:
- `latest`: Latest build from main/master
- `main-abc123`: Branch name + short commit SHA
- `1.0.0`: Semantic version (if tagged)

## Deployment Process

1. Code is pushed to main/master
2. GitHub Actions builds Docker image
3. Image is pushed to DockerHub
4. SSH connection to EC2
5. Pull latest image
6. Run migrations
7. Restart containers
8. Health check

## Monitoring

View workflow runs at: `https://github.com/<username>/<repo>/actions`

## Troubleshooting

### Build fails
- Check Docker build logs
- Verify requirements.txt is up to date
- Check DockerHub credentials

### Deploy fails
- Verify EC2_HOST is correct
- Check SSH key format (should be complete private key)
- Ensure EC2 security group allows SSH from GitHub Actions IPs
- Check EC2 instance is running

### Application doesn't start
- SSH to EC2: `ssh -i key.pem ec2-user@<EC2_IP>`
- Check logs: `cd /opt/cinematch && docker-compose logs`
- Verify environment variables are set correctly

