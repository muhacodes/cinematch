# CineMatch AWS Infrastructure - Simplified

Simple, cost-effective deployment with everything on one EC2 instance.

## Architecture

```
┌─────────────────────────────────────────┐
│          VPC (10.0.0.0/16)              │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │   Public Subnet (10.0.1.0/24)   │   │
│  │                                 │   │
│  │   ┌─────────────────────────┐   │   │
│  │   │    EC2 (t2.micro)       │   │   │
│  │   │                         │   │   │
│  │   │  - Django (Docker)      │   │   │
│  │   │  - Redis (Docker)       │   │   │
│  │   │  - Nginx               │   │   │
│  │   │  - Certbot (Free SSL)  │   │   │
│  │   └───────────┬─────────────┘   │   │
│  │               │                 │   │
│  └───────────────┼─────────────────┘   │
│                  │                     │
│  ┌───────────────▼─────────────────┐   │
│  │   Private Subnet (10.0.10.0/24) │   │
│  │                                 │   │
│  │   ┌─────────────────────────┐   │   │
│  │   │  RDS PostgreSQL         │   │   │
│  │   │  (db.t3.micro)          │   │   │
│  │   │  PRIVATE ONLY          │   │   │
│  │   └─────────────────────────┘   │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Key Points:**
- ✅ Single EC2 instance with **Ubuntu 22.04 LTS**
- ✅ Redis runs inside EC2 (no ElastiCache cost!)
- ✅ Nginx for reverse proxy
- ✅ Certbot for FREE SSL certificate
- ✅ RDS in private subnet (secure)
- ✅ Domain: api.cinematch.muhacodes.com
- 🔒 **Secrets stored in AWS SSM (encrypted)**
- 🔒 **No secrets in user data or code**

## Cost

**Monthly: ~$20-25** (or $0 for first year with free tier)

- EC2 t2.micro: $8-10/month (FREE for 12 months)
- RDS db.t3.micro: $12-15/month (FREE for 12 months)
- Data transfer: $1-3/month

**No ElastiCache cost!** Redis runs on EC2.

## Prerequisites

1. AWS Account
2. AWS CLI configured
3. Terraform installed
4. EC2 Key Pair
5. DockerHub account

## Quick Start

### 1. Configure Variables (Using .env - Secure!)

**Option A: Using .env file (Recommended)**

```bash
cd terraform

# Create .env file with TF_VAR_ prefix
cat > .env <<EOF
TF_VAR_aws_region=us-east-1
TF_VAR_environment=production
TF_VAR_project_name=cinematch
TF_VAR_domain_name=api.cinematch.muhacodes.com
TF_VAR_ec2_key_name=your-key-name
TF_VAR_db_password=your-strong-password
TF_VAR_db_name=cinematch
TF_VAR_db_username=cinematch_admin
TF_VAR_ec2_instance_type=t2.micro
TF_VAR_dockerhub_image=yourusername/cinematch:latest
TF_VAR_tmdb_token=your-tmdb-token
TF_VAR_llm_api_key=your-openai-key
TF_VAR_django_secret_key=generate-this
EOF

# Load environment variables
source ./load-env.sh
```

**Option B: Using terraform.tfvars (Traditional)**

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
# Fill in your values
```

**⚠️ Security Note:** Using `.env` with `TF_VAR_*` is more secure as it:
- Keeps secrets in `.gitignore`
- Works with environment-based workflows
- Never gets committed to version control

See [ENV_SETUP.md](./ENV_SETUP.md) for detailed instructions.

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Wait ~10 minutes for deployment. Secrets will be:
- ✅ Stored encrypted in AWS SSM Parameter Store
- ✅ Fetched at runtime by EC2 (not in user data!)
- ✅ Accessed by GitHub Actions via SSM

### 3. Get the IP Address

```bash
terraform output ec2_public_ip
```

### 4. Point DNS to EC2

Go to your DNS provider and add:

```
Type: A
Name: api.cinematch
Value: <EC2_PUBLIC_IP>
TTL: 300
```

Wait 5-10 minutes for DNS propagation.

### 5. Setup SSL Certificate

```bash
# SSH to server
ssh -i your-key.pem ec2-user@<EC2_IP>

# Run SSL setup (after DNS is pointed)
sudo /root/setup-ssl.sh
```

This will:
- Get a FREE SSL certificate from Let's Encrypt
- Configure Nginx for HTTPS
- Setup auto-renewal

### 6. Test Your API

```bash
curl https://api.cinematch.muhacodes.com/api/trending/
curl https://api.cinematch.muhacodes.com/api/genres/
```

## What Gets Installed on EC2

The EC2 instance automatically installs:

1. **Docker & Docker Compose** - For running containers
2. **Nginx** - Reverse proxy and web server
3. **Certbot** - For free SSL certificates
4. **Redis Container** - Caching (no separate ElastiCache!)
5. **Django Container** - Your application

## Directory Structure on EC2

```
/opt/cinematch/
├── .env                 # Environment variables
├── docker-compose.yml   # Services definition
└── staticfiles/        # Django static files

/etc/nginx/conf.d/
└── cinematch.conf      # Nginx configuration

/root/
├── setup-ssl.sh        # SSL setup script
└── update-app.sh       # App update script
```

## Useful Commands

### SSH to Server
```bash
ssh -i your-key.pem ec2-user@<EC2_IP>
```

### View Logs
```bash
# Docker logs
cd /opt/cinematch
docker-compose logs -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Update Application
```bash
# From your local machine
docker build -f Dockerfile.prod -t yourusername/cinematch:latest .
docker push yourusername/cinematch:latest

# On the server (or SSH and run)
sudo /root/update-app.sh
```

### Restart Services
```bash
# Docker services
cd /opt/cinematch
docker-compose restart

# Nginx
sudo systemctl restart nginx
```

### Check Status
```bash
# Docker containers
docker-compose ps

# Nginx
sudo systemctl status nginx

# Redis
docker-compose exec redis redis-cli ping
```

## Troubleshooting

### SSL Certificate Fails

```bash
# Check DNS is pointing correctly
nslookup api.cinematch.muhacodes.com

# Check Nginx is running
sudo systemctl status nginx

# Try getting certificate manually
sudo certbot --nginx -d api.cinematch.muhacodes.com
```

### Can't Connect to RDS

```bash
# From EC2, test database connection
docker-compose exec web python manage.py dbshell
```

### Redis Not Working

```bash
# Check Redis container
docker-compose ps redis

# Test Redis
docker-compose exec redis redis-cli ping
# Should return: PONG
```

### Application Won't Start

```bash
cd /opt/cinematch
docker-compose logs web

# Check environment variables
cat .env
```

## Security

### Restrict SSH Access

Edit `security_groups.tf`:
```hcl
# Change this line:
cidr_blocks = ["0.0.0.0/0"]

# To your IP:
cidr_blocks = ["YOUR_IP/32"]
```

Then apply:
```bash
terraform apply
```

## Monitoring

### Check Resource Usage
```bash
# CPU and Memory
top
htop  # if installed

# Disk space
df -h

# Docker stats
docker stats
```

### Setup CloudWatch (Optional)
```bash
# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent

# Configure and start
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s
```

## Backup

### Database Backups

RDS has automatic backups enabled (7-day retention).

Manual snapshot:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier cinematch-db \
  --db-snapshot-identifier cinematch-backup-$(date +%Y%m%d)
```

### Application Backups

```bash
# SSH to server
ssh -i your-key.pem ec2-user@<EC2_IP>

# Backup docker-compose and .env
cd /opt/cinematch
sudo tar -czf ~/cinematch-backup.tar.gz .env docker-compose.yml
```

## Scaling

If you outgrow t2.micro:

1. Update `terraform/variables.tf`:
   ```hcl
   ec2_instance_type = "t3.small"  # or t3.medium
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

## Cleanup

To destroy everything:
```bash
terraform destroy
```

**Warning:** This deletes the database!

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Point DNS
3. ✅ Setup SSL
4. 📊 Setup monitoring
5. 🔒 Restrict SSH access
6. 💾 Schedule backups
7. 📧 Configure error notifications

## Support

- Terraform issues: Check this README
- SSL issues: Check Certbot logs in `/var/log/letsencrypt/`
- Application issues: Check Docker logs
