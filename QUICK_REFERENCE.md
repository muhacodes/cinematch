# CineMatch - Quick Reference Guide

## 🚀 Initial Setup

### 1. Configure Environment Variables

```bash
cd terraform

# Create .env file
cat > .env <<'EOF'
TF_VAR_aws_region=us-east-1
TF_VAR_environment=production
TF_VAR_project_name=cinematch
TF_VAR_domain_name=api.cinematch.muhacodes.com
TF_VAR_ec2_key_name=your-ec2-key-name
TF_VAR_db_name=cinematch
TF_VAR_db_username=cinematch_admin
TF_VAR_db_password=CHANGE_ME
TF_VAR_ec2_instance_type=t2.micro
TF_VAR_dockerhub_image=yourusername/cinematch:latest
TF_VAR_tmdb_token=CHANGE_ME
TF_VAR_llm_api_key=CHANGE_ME
TF_VAR_django_secret_key=CHANGE_ME
EOF

# Load environment
source ./load-env.sh
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Get Connection Info

```bash
# Get EC2 public IP
terraform output ec2_public_ip

# Get SSH command
terraform output ssh_command

# Get SSM command (more secure)
terraform output ssm_command
```

### 4. Setup DNS

```bash
# Get IP address
IP=$(terraform output -raw ec2_public_ip)

# Add A record: api.cinematch.muhacodes.com -> $IP
# Wait 5-10 minutes for DNS propagation
```

### 5. Setup SSL Certificate

```bash
# Connect to server
ssh -i ~/.ssh/your-key.pem ubuntu@$(terraform output -raw ec2_public_ip)

# Run SSL setup script
sudo /root/setup-ssl.sh
```

---

## 🔧 Common Commands

### Terraform Operations

```bash
# Load environment variables
cd terraform && source ./load-env.sh

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy everything
terraform destroy

# Show outputs
terraform output

# Show specific output
terraform output -raw ec2_public_ip
```

### EC2 Access

```bash
# SSH (traditional)
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>

# SSM Session Manager (more secure, no SSH key needed)
aws ssm start-session --target <instance-id>

# Get instance ID
terraform output -raw ec2_instance_id
```

### Application Management

```bash
# SSH into server
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>

# Update application (pulls latest Docker image and secrets)
sudo /root/update-app.sh

# View logs
cd /opt/cinematch
docker-compose logs -f web
docker-compose logs -f redis

# Restart services
docker-compose restart

# Check status
docker-compose ps

# Manual deployment
cd /opt/cinematch
docker-compose pull
docker-compose up -d
docker-compose exec -T web python manage.py migrate
docker-compose exec -T web python manage.py collectstatic --noinput
```

### Secrets Management (SSM)

```bash
# List all secrets
aws ssm describe-parameters \
  --filters "Key=Name,Values=/cinematch/production/*"

# Get a secret (decrypted)
aws ssm get-parameter \
  --name "/cinematch/production/django-secret-key" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text

# Update a secret
aws ssm put-parameter \
  --name "/cinematch/production/django-secret-key" \
  --value "new-secret-value" \
  --type "SecureString" \
  --overwrite

# After updating secrets, restart the app
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>
sudo /root/update-app.sh
```

### Database Operations

```bash
# Connect to RDS from EC2
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>

# Install PostgreSQL client
sudo apt-get update
sudo apt-get install -y postgresql-client

# Connect to database
DB_HOST=$(aws ssm get-parameter --name "/cinematch/production/db-host" --query 'Parameter.Value' --output text --region us-east-1)
DB_PASS=$(aws ssm get-parameter --name "/cinematch/production/db-password" --with-decryption --query 'Parameter.Value' --output text --region us-east-1)

psql -h $DB_HOST -U cinematch_admin -d cinematch

# Run Django migrations
cd /opt/cinematch
docker-compose exec -T web python manage.py migrate

# Create superuser
docker-compose exec -T web python manage.py createsuperuser
```

### GitHub Actions

```bash
# View deployment workflow
cat .github/workflows/deploy.yml

# Trigger manual deployment
# Go to: GitHub → Actions → Build and Deploy to AWS → Run workflow

# Check deployment logs
# Go to: GitHub → Actions → Latest workflow run
```

---

## 🐛 Troubleshooting

### Application Not Starting

```bash
# Check logs
cd /opt/cinematch
docker-compose logs -f

# Check if containers are running
docker-compose ps

# Restart everything
docker-compose down
docker-compose up -d

# Check .env file
sudo cat .env
```

### SSL Certificate Issues

```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx config
sudo nginx -t

# View nginx logs
sudo tail -f /var/log/nginx/error.log

# Re-run certbot
sudo /root/setup-ssl.sh
```

### Database Connection Issues

```bash
# Check if RDS is accessible
cd /opt/cinematch
docker-compose exec web python manage.py dbshell

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=cinematch-rds-sg" \
  --query 'SecurityGroups[0].IpPermissions'
```

### SSM Parameter Issues

```bash
# Check IAM role permissions
aws iam get-role-policy \
  --role-name cinematch-ec2-role \
  --policy-name cinematch-ec2-ssm-parameters

# Test SSM from EC2
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>
aws ssm get-parameter \
  --name "/cinematch/production/django-secret-key" \
  --with-decryption \
  --region us-east-1
```

### GitHub Actions Deployment Fails

```bash
# Check if SSM Session Manager is working
aws ssm start-session --target <instance-id>

# Check instance IAM role
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Check AWS credentials in GitHub
# Settings → Secrets and variables → Actions
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
```

---

## 📊 Monitoring

### Check Application Health

```bash
# HTTP health check
curl http://<ec2-ip>/api/trending/

# HTTPS health check
curl https://api.cinematch.muhacodes.com/api/trending/

# Check from inside container
cd /opt/cinematch
docker-compose exec web curl localhost:8000/api/trending/
```

### System Resources

```bash
# SSH into server
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>

# Check disk space
df -h

# Check memory
free -h

# Check CPU
top

# Check Docker resources
docker stats
```

### Logs

```bash
# Application logs
cd /opt/cinematch
docker-compose logs -f web

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u docker -f
```

---

## 🔒 Security

### Rotate Secrets

```bash
# 1. Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# 2. Update in SSM
aws ssm put-parameter \
  --name "/cinematch/production/django-secret-key" \
  --value "$NEW_SECRET" \
  --type "SecureString" \
  --overwrite

# 3. Update application
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>
sudo /root/update-app.sh
```

### Audit Access

```bash
# View SSM parameter access logs (requires CloudTrail)
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=/cinematch/production/django-secret-key \
  --max-results 10

# Check who accessed EC2
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=<instance-id> \
  --max-results 10
```

---

## 📚 Documentation

- [SECURITY.md](./SECURITY.md) - Security architecture
- [SECURITY_AUDIT_RESULTS.md](./SECURITY_AUDIT_RESULTS.md) - Audit results
- [terraform/README.md](./terraform/README.md) - Infrastructure docs
- [terraform/ENV_SETUP.md](./terraform/ENV_SETUP.md) - Environment setup

---

## 🆘 Emergency Procedures

### Application Down

```bash
# 1. Check if containers are running
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2-ip>
cd /opt/cinematch
docker-compose ps

# 2. Restart
docker-compose restart

# 3. If still down, rebuild
docker-compose down
docker-compose pull
docker-compose up -d

# 4. Check logs
docker-compose logs -f
```

### Database Corruption

```bash
# 1. Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier cinematch-db

# 2. Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier cinematch-db-restored \
  --db-snapshot-identifier <snapshot-id>

# 3. Update SSM parameter with new host
aws ssm put-parameter \
  --name "/cinematch/production/db-host" \
  --value "<new-rds-endpoint>" \
  --overwrite
```

### Security Breach

```bash
# 1. Rotate all secrets immediately
# 2. Check CloudTrail for unauthorized access
# 3. Review security groups
# 4. Update all passwords
# 5. Review IAM policies
```

---

## 💰 Cost Optimization

### Check Current Costs

```bash
# View AWS Cost Explorer
# https://console.aws.amazon.com/cost-management/

# List resources
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]'
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]'
```

### Reduce Costs

```bash
# Stop non-production instances
aws ec2 stop-instances --instance-ids <instance-id>

# Downgrade RDS
# Edit terraform/.env: TF_VAR_db_instance_class=db.t3.micro
terraform apply

# Delete unused snapshots
aws rds describe-db-snapshots --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]'
aws rds delete-db-snapshot --db-snapshot-identifier <snapshot-id>
```

---

**Last Updated:** 2025-11-28
**Version:** 2.0.0 (Security Hardened)

