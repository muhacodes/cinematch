# 🎯 START HERE - CineMatch Security Update

## ⚡ Quick Start Guide

Your infrastructure has been completely secured! All 4 requirements are now met:

✅ **1. Not exposing .env variables** - Using Terraform variables from `.env`  
✅ **2. Using Ubuntu for EC2** - Changed from Amazon Linux to Ubuntu 22.04 LTS  
✅ **3. GitHub Actions use SSM** - No hardcoded secrets, all via AWS SSM  
✅ **4. User data installs requirements** - Fetches secrets from SSM at runtime  

---

## 🚀 Deploy in 3 Steps

### Step 1: Create Environment File (2 minutes)

```bash
cd terraform

# Create .env file with your secrets
cat > .env <<'EOF'
TF_VAR_aws_region=us-east-1
TF_VAR_environment=production
TF_VAR_project_name=cinematch

# Your domain
TF_VAR_domain_name=api.cinematch.muhacodes.com

# Database settings
TF_VAR_db_name=cinematch
TF_VAR_db_username=cinematch_admin
TF_VAR_db_password=CHANGE_THIS_NOW

# EC2 settings
TF_VAR_ec2_instance_type=t2.micro
TF_VAR_ec2_key_name=your-ec2-key-pair-name

# DockerHub
TF_VAR_dockerhub_image=yourusername/cinematch:latest

# API Keys - CHANGE THESE!
TF_VAR_tmdb_token=your-tmdb-read-access-token
TF_VAR_llm_api_key=your-openai-api-key
TF_VAR_django_secret_key=your-django-secret-key
EOF

# Generate a secure Django secret key
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### Step 2: Load Environment & Deploy (10 minutes)

```bash
# Load environment variables
source ./load-env.sh

# Initialize Terraform (first time only)
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 3: Get Your Server IP & Setup DNS

```bash
# Get your EC2 public IP
terraform output ec2_public_ip

# Add this A record to your DNS:
# api.cinematch.muhacodes.com → <your-ec2-ip>

# Wait 5-10 minutes for DNS propagation
```

---

## 🔌 Connect to Your Server

### Option A: SSM Session Manager (Recommended - No SSH Key Needed!)

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Connect
aws ssm start-session --target $INSTANCE_ID
```

### Option B: Traditional SSH

```bash
# Get IP
EC2_IP=$(terraform output -raw ec2_public_ip)

# Connect
ssh -i ~/.ssh/your-key.pem ubuntu@$EC2_IP
```

---

## 🔐 Setup SSL Certificate

After DNS is pointed to your server:

```bash
# Connect to server
ssh -i ~/.ssh/your-key.pem ubuntu@<your-ec2-ip>

# Run SSL setup
sudo /root/setup-ssl.sh

# Done! Your site is now HTTPS
```

---

## 📊 What's Different Now?

### Before (INSECURE) ❌
- Secrets hardcoded in EC2 user data
- Visible in AWS Console
- Using Amazon Linux 2023
- GitHub Secrets for deployment
- terraform.tfvars with secrets

### After (SECURE) ✅
- Secrets in AWS SSM Parameter Store (encrypted)
- Nothing visible in user data
- Using Ubuntu 22.04 LTS
- SSM Session Manager for deployment
- .env file (gitignored)

---

## 📚 Documentation

Read these in order:

1. **[README_SECURITY_UPDATE.md](./README_SECURITY_UPDATE.md)** ⭐ Start here for overview
2. **[CHANGES_SUMMARY.md](./CHANGES_SUMMARY.md)** - What was changed
3. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Command cheat sheet
4. **[SECURITY.md](./SECURITY.md)** - Security architecture
5. **[SECURITY_AUDIT_RESULTS.md](./SECURITY_AUDIT_RESULTS.md)** - Detailed audit

### Terraform Specific
- **[terraform/ENV_SETUP.md](./terraform/ENV_SETUP.md)** - Environment setup
- **[terraform/README.md](./terraform/README.md)** - Infrastructure guide

---

## 🛠️ Common Commands

```bash
# Deploy/Update Infrastructure
cd terraform
source ./load-env.sh
terraform apply

# Connect to EC2
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# Update Application
ssh ubuntu@<ip> sudo /root/update-app.sh

# View Logs
ssh ubuntu@<ip> "cd /opt/cinematch && docker-compose logs -f"

# Rotate Secret
aws ssm put-parameter \
  --name "/cinematch/production/django-secret-key" \
  --value "new-secret" \
  --type "SecureString" \
  --overwrite
```

---

## ✅ Pre-Deployment Checklist

- [ ] Created `terraform/.env` with all variables
- [ ] Changed all `CHANGE_THIS_NOW` values
- [ ] Generated secure Django secret key
- [ ] Created EC2 key pair in AWS Console
- [ ] Set up AWS CLI credentials (`aws configure`)
- [ ] Loaded environment variables (`source ./load-env.sh`)
- [ ] Reviewed terraform plan

---

## 🎯 Post-Deployment Checklist

- [ ] Got EC2 public IP from terraform output
- [ ] Added DNS A record pointing to EC2 IP
- [ ] Waited for DNS propagation (5-10 minutes)
- [ ] Connected to EC2 and ran SSL setup script
- [ ] Verified site works at https://api.cinematch.muhacodes.com
- [ ] Set up GitHub Actions secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

---

## 🐛 Having Issues?

### Terraform can't find variables
```bash
cd terraform
source ./load-env.sh  # Run this first!
terraform plan
```

### Can't connect to EC2
```bash
# Check instance is running
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw ec2_instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'

# Try SSM instead of SSH
aws ssm start-session --target $(terraform output -raw ec2_instance_id)
```

### Secrets not loading
```bash
# Test SSM from EC2
ssh ubuntu@<ip>
aws ssm get-parameter \
  --name "/cinematch/production/django-secret-key" \
  --with-decryption \
  --region us-east-1
```

---

## 📁 Project Structure

```
CineMatch/
├── START_HERE.md                   ← You are here!
├── README_SECURITY_UPDATE.md       ← Security changes overview
├── CHANGES_SUMMARY.md              ← What changed
├── QUICK_REFERENCE.md              ← Command reference
├── SECURITY.md                     ← Security architecture
├── SECURITY_AUDIT_RESULTS.md       ← Audit findings
│
├── terraform/
│   ├── .env                        ← Create this with your secrets!
│   ├── load-env.sh                 ← Run this to load .env
│   ├── ENV_SETUP.md                ← Environment setup guide
│   ├── ssm.tf                      ← NEW: SSM Parameter Store
│   ├── ec2.tf                      ← UPDATED: Ubuntu + SSM
│   ├── rds.tf                      ← Database config
│   ├── vpc.tf                      ← Network config
│   └── ...
│
├── .github/workflows/
│   └── deploy.yml                  ← UPDATED: SSM deployment
│
└── ...
```

---

## 💡 Key Concepts

### AWS SSM Parameter Store
Your secrets are stored encrypted in AWS and fetched at runtime. No secrets in code!

```
terraform/.env (local) 
    ↓ 
AWS SSM (encrypted) 
    ↓ 
EC2 fetches at runtime
```

### SSM Session Manager
Connect to EC2 without SSH keys using AWS IAM authentication.

```
You → AWS IAM → SSM Service → EC2
✅ No SSH keys to manage
✅ Full audit trail
✅ More secure
```

### Terraform Variables from .env
Use `TF_VAR_*` prefix to pass variables to Terraform securely.

```bash
# In .env file
TF_VAR_db_password=secret123

# Terraform automatically reads it
variable "db_password" {
  # Gets value from TF_VAR_db_password
}
```

---

## 🎉 You're Ready!

Everything is configured and secure. Just follow the 3 deployment steps above and you'll be live!

**Need help?** Check the documentation files or the troubleshooting section.

---

**Last Updated:** November 28, 2025  
**Status:** ✅ Production Ready  
**Security:** 🔒 Fully Secured

