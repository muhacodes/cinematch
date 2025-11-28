# Security Architecture

## 🔒 Secrets Management

This project uses **AWS Systems Manager (SSM) Parameter Store** for secure secrets management. No secrets are hardcoded in code, Terraform files, or CI/CD configurations.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Secrets Flow                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Developer (.env) → Terraform → SSM Parameter Store      │
│                                    (Encrypted)              │
│                                                             │
│  2. EC2 Instance → IAM Role → SSM Parameter Store          │
│                                ↓                            │
│                          Fetch secrets at runtime           │
│                                                             │
│  3. GitHub Actions → IAM Role → SSM Parameter Store        │
│                                  ↓                          │
│                            Deploy via SSM Session Manager   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🛡️ Security Features

### 1. Terraform Variables from .env
- Secrets are loaded from `.env` file (not committed to git)
- Environment variables prefixed with `TF_VAR_*`
- No secrets in `terraform.tfvars` or code

### 2. AWS SSM Parameter Store
- All secrets stored encrypted in SSM
- Accessed via IAM roles (no keys exposed)
- Encrypted at rest with AWS KMS

### 3. EC2 User Data Security
- **NO secrets in user data** (unlike before)
- Fetches secrets from SSM at runtime
- User data only contains:
  - Installation commands
  - SSM fetch logic
  - Configuration templates

### 4. GitHub Actions via SSM
- Uses AWS SSM Session Manager (no SSH needed)
- No secrets stored in GitHub
- Uses AWS IAM roles for authentication
- Optional: SSH key stored in SSM (encrypted)

### 5. Runtime Security
- Secrets fetched on-demand from SSM
- `.env` file permissions: `600` (owner read/write only)
- Owned by `root:root`
- Never logged or exposed

## 📋 Setup Checklist

### Initial Setup

1. **Create `.env` file for Terraform**
   ```bash
   cd terraform
   cp ENV_SETUP.md .env  # Follow the template
   # Edit .env with your actual values
   ```

2. **Load environment variables**
   ```bash
   source ./load-env.sh
   ```

3. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure GitHub Actions**
   - Set up AWS credentials in GitHub Secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
   - Optionally add SSH key to SSM:
     ```bash
     aws ssm put-parameter \
       --name "/cinematch/production/ec2-ssh-key" \
       --value "$(cat ~/.ssh/your-key.pem)" \
       --type "SecureString"
     ```

## 🔍 Security Verification

### Check 1: No Secrets in User Data
```bash
# View user data (should see SSM fetch logic, not actual secrets)
aws ec2 describe-instance-attribute \
  --instance-id <instance-id> \
  --attribute userData \
  --query 'UserData.Value' \
  --output text | base64 --decode
```

### Check 2: SSM Parameters Encrypted
```bash
# List all parameters
aws ssm describe-parameters \
  --filters "Key=Name,Values=/cinematch/production/*"

# Get a parameter (will show encrypted value)
aws ssm get-parameter \
  --name "/cinematch/production/django-secret-key" \
  --with-decryption
```

### Check 3: IAM Permissions
```bash
# Verify EC2 IAM role has SSM access
aws iam get-role-policy \
  --role-name cinematch-ec2-role \
  --policy-name cinematch-ec2-ssm-parameters
```

## 🚨 Security Best Practices

### DO ✅
- Keep `.env` in `.gitignore`
- Use strong, unique passwords for each environment
- Rotate secrets regularly (update SSM parameters)
- Use AWS KMS for encryption
- Enable CloudTrail for audit logging
- Use SSM Session Manager instead of SSH
- Restrict SSH to specific IPs (security group)
- Enable MFA on AWS accounts

### DON'T ❌
- Commit `.env` or any secrets to git
- Use default/weak passwords
- Share AWS credentials
- Expose secrets in logs
- Use same secrets across environments
- Leave SSH open to `0.0.0.0/0` in production
- Hardcode secrets anywhere in code

## 🔄 Rotating Secrets

### Update a Secret

1. **Update in SSM Parameter Store**
   ```bash
   aws ssm put-parameter \
     --name "/cinematch/production/django-secret-key" \
     --value "new-secret-value" \
     --type "SecureString" \
     --overwrite
   ```

2. **Update on EC2**
   ```bash
   # SSH or SSM into EC2
   ssh -i your-key.pem ubuntu@<ec2-ip>
   
   # Run update script (fetches latest from SSM)
   sudo /root/update-app.sh
   ```

3. **Restart application**
   ```bash
   cd /opt/cinematch
   docker-compose restart
   ```

## 📊 Secrets Inventory

| Secret | Stored In | Accessed By | Encrypted |
|--------|-----------|-------------|-----------|
| Django Secret Key | SSM | EC2, GitHub Actions | ✅ Yes |
| Database Password | SSM | EC2 | ✅ Yes |
| TMDB Token | SSM | EC2 | ✅ Yes |
| LLM API Key | SSM | EC2 | ✅ Yes |
| SSH Private Key | SSM | GitHub Actions | ✅ Yes |
| DockerHub Token | GitHub Secrets | GitHub Actions | ✅ Yes |

## 📞 Incident Response

If secrets are compromised:

1. **Immediately rotate all secrets** in AWS SSM
2. **Update GitHub secrets** if needed
3. **Restart all services** to use new secrets
4. **Review CloudTrail logs** for unauthorized access
5. **Check AWS GuardDuty** for threats
6. **Audit IAM permissions** and remove unnecessary access

## 🔗 Related Documentation

- [terraform/ENV_SETUP.md](terraform/ENV_SETUP.md) - Environment setup
- [terraform/README.md](terraform/README.md) - Infrastructure documentation
- [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

