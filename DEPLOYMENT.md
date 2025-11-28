# CineMatch AWS Deployment Guide - Simplified

Deploy CineMatch on a single EC2 instance with Nginx, Redis, and free SSL!

## Architecture

```
                    Internet
                        │
                        ▼
              api.cinematch.muhacodes.com
                        │
                        ▼
┌────────────────────────────────────────────────┐
│              VPC (10.0.0.0/16)                 │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │     EC2 t2.micro (Public Subnet)         │ │
│  │                                          │ │
│  │  ┌────────────────────────────────────┐ │ │
│  │  │  Nginx (Port 80/443)               │ │ │
│  │  │  + Certbot (Free SSL)              │ │ │
│  │  └──────────────┬─────────────────────┘ │ │
│  │                 │                        │ │
│  │  ┌──────────────▼─────────────────────┐ │ │
│  │  │  Docker Compose:                   │ │ │
│  │  │  - Django (Port 8000)              │ │ │
│  │  │  - Redis (Port 6379)               │ │ │
│  │  └──────────────┬─────────────────────┘ │ │
│  │                 │                        │ │
│  └─────────────────┼────────────────────────┘ │
│                    │                          │
│  ┌─────────────────▼────────────────────────┐ │
│  │  RDS PostgreSQL (Private Subnet)         │ │
│  │  - Only accessible from EC2              │ │
│  │  - db.t3.micro                           │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

**What you get:**
- ✅ Single EC2 instance (t2.micro - cheapest!)
- ✅ Redis inside EC2 (no ElastiCache cost)
- ✅ Nginx for reverse proxy
- ✅ **FREE SSL** with Certbot/Let's Encrypt
- ✅ Private RDS PostgreSQL
- ✅ Domain: `api.cinematch.muhacodes.com`

**Cost: ~$20-25/month** (or $0 first year with free tier!)

## Prerequisites

- AWS account
- AWS CLI configured
- Terraform installed
- EC2 key pair (create in AWS Console)
- DockerHub account
- Access to muhacodes.com DNS settings

## Step-by-Step Deployment

### Step 1: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in your values:
```hcl
domain_name       = "api.cinematch.muhacodes.com"
ec2_key_name      = "cinematch-key"  # Your EC2 key pair name
db_password       = "SuperSecure123!"
dockerhub_image   = "yourusername/cinematch:latest"
tmdb_token        = "eyJhbGc..."
llm_api_key       = "sk-..."
django_secret_key = "django-secret-from-generator"
```

Generate Django secret:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### Step 2: Build and Push Docker Image

```bash
# Build production image
docker build -f Dockerfile.prod -t yourusername/cinematch:latest .

# Login to DockerHub
docker login

# Push image
docker push yourusername/cinematch:latest
```

### Step 3: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy!
terraform apply
```

**Wait ~10 minutes** for AWS to provision everything.

### Step 4: Get EC2 IP Address

```bash
terraform output ec2_public_ip
# Output: 54.123.45.67
```

### Step 5: Point DNS to EC2

Go to your DNS provider (muhacodes.com) and add:

```
Type: A
Name: api.cinematch
Value: <EC2_PUBLIC_IP>
TTL: 300 (5 minutes)
```

**Wait 5-10 minutes** for DNS propagation.

Test DNS:
```bash
nslookup api.cinematch.muhacodes.com
# Should return your EC2 IP
```

### Step 6: Setup Free SSL Certificate

Once DNS is propagated:

```bash
# SSH to your server
ssh -i cinematch-key.pem ec2-user@<EC2_IP>

# Run SSL setup script
sudo /root/setup-ssl.sh
```

This will:
- Get a FREE SSL certificate from Let's Encrypt
- Configure Nginx for HTTPS with redirect
- Setup auto-renewal (certificate renews automatically!)

### Step 7: Test Your API!

```bash
# Test endpoints
curl https://api.cinematch.muhacodes.com/api/trending/
curl https://api.cinematch.muhacodes.com/api/genres/
curl https://api.cinematch.muhacodes.com/api/top-rated/

# Test recommendations
curl -X POST https://api.cinematch.muhacodes.com/api/recommendations/ \
  -H "Content-Type: application/json" \
  -d '{
    "movie_ids": [550, 13, 680],
    "preferences": {
      "genres": ["Action", "Thriller"],
      "mood": "Intense",
      "description": "I like mind-bending thrillers"
    }
  }'
```

## 🎉 Done! Your API is live!

## Daily Operations

### View Logs

```bash
# SSH to server
ssh -i cinematch-key.pem ec2-user@<EC2_IP>

# Docker logs (Django + Redis)
cd /opt/cinematch
docker-compose logs -f

# Just Django
docker-compose logs -f web

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Update Application

After pushing new code:

```bash
# Build and push new image
docker build -f Dockerfile.prod -t yourusername/cinematch:latest .
docker push yourusername/cinematch:latest

# Update on server (SSH or run remotely)
ssh -i cinematch-key.pem ec2-user@<EC2_IP> 'sudo /root/update-app.sh'
```

The update script:
- Pulls latest image
- Runs migrations
- Restarts containers
- Cleans old images

### Restart Services

```bash
# Restart everything
cd /opt/cinematch
docker-compose restart

# Restart just Django
docker-compose restart web

# Restart Nginx
sudo systemctl restart nginx
```

### Check Status

```bash
# Docker containers
docker-compose ps

# Redis health
docker-compose exec redis redis-cli ping
# Should return: PONG

# Database connection
docker-compose exec web python manage.py dbshell

# Disk space
df -h

# Resource usage
docker stats
```

## CI/CD with GitHub Actions

The GitHub Actions pipeline automatically:
1. Builds Docker image on push to `main`
2. Pushes to DockerHub
3. SSHs to EC2
4. Runs update script

**Required GitHub Secrets:**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_HOST` (your EC2 IP)
- `EC2_SSH_PRIVATE_KEY` (content of .pem file)

Just push to main and it auto-deploys! 🚀

## Troubleshooting

### SSL Certificate Fails

```bash
# 1. Verify DNS is working
nslookup api.cinematch.muhacodes.com

# 2. Check Nginx is running
sudo systemctl status nginx

# 3. Check port 80 is accessible
curl http://api.cinematch.muhacodes.com

# 4. Try manual certificate
sudo certbot --nginx -d api.cinematch.muhacodes.com -v
```

### Application Not Starting

```bash
cd /opt/cinematch

# Check logs
docker-compose logs web

# Check .env file
cat .env

# Restart
docker-compose restart web
```

### Can't Connect to Database

```bash
# Test from EC2
docker-compose exec web python manage.py dbshell

# Check RDS endpoint
aws rds describe-db-instances --db-instance-identifier cinematch-db

# Verify security groups allow connection
```

### Redis Not Working

```bash
# Check Redis container
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping

# Check logs
docker-compose logs redis
```

### Out of Disk Space

```bash
# Check space
df -h

# Clean Docker
docker system prune -af
docker volume prune -f

# Clean logs
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
```

## Security Hardening

### 1. Restrict SSH Access

Edit `terraform/security_groups.tf`:

```hcl
# Change this:
cidr_blocks = ["0.0.0.0/0"]

# To your IP only:
cidr_blocks = ["YOUR_IP/32"]
```

Apply:
```bash
terraform apply
```

### 2. Setup Fail2Ban

```bash
# SSH to server
sudo yum install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. Enable Automatic Security Updates

```bash
sudo yum install -y yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron
```

## Monitoring

### Setup CloudWatch Alarms

```bash
# CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name cinematch-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### Install Monitoring Tools

```bash
# SSH to server
sudo yum install -y htop iotop

# Use
htop        # CPU/Memory
iotop       # Disk I/O
docker stats  # Container stats
```

## Backup Strategy

### Database Backups

RDS automatically backs up (7-day retention).

Manual snapshot:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier cinematch-db \
  --db-snapshot-identifier backup-$(date +%Y%m%d)
```

### Application Backup

```bash
# Backup configuration
ssh -i cinematch-key.pem ec2-user@<EC2_IP>
cd /opt/cinematch
sudo tar -czf ~/backup-$(date +%Y%m%d).tar.gz .env docker-compose.yml
```

## Scaling

### Vertical Scaling (Bigger Instance)

```hcl
# terraform/variables.tf
ec2_instance_type = "t3.small"  # or t3.medium
```

```bash
terraform apply
```

### Horizontal Scaling

For high traffic, consider:
1. Application Load Balancer
2. Multiple EC2 instances
3. Auto Scaling Group
4. Separate Redis server

## Cost Optimization

**Current setup (~$20-25/month):**
- EC2 t2.micro: $8-10/month
- RDS db.t3.micro: $12-15/month
- Data transfer: $1-3/month

**To reduce costs:**
- Stop EC2 when not testing: `aws ec2 stop-instances --instance-ids i-xxx`
- Delete RDS when not needed (use snapshots)
- Use reserved instances (save up to 75%)

## Clean Up

**⚠️ WARNING: This deletes everything!**

```bash
cd terraform
terraform destroy
```

This removes:
- EC2 instance
- RDS database (and all data!)
- VPC and networking
- Everything

## Advanced: Custom Domain for Frontend

If you want `cinematch.muhacodes.com` (without api):

1. Point `cinematch.muhacodes.com` to your frontend server
2. Update CORS in `.env`:
   ```
   CORS_ALLOWED_ORIGINS=https://cinematch.muhacodes.com
   ```
3. Restart: `docker-compose restart web`

## Next Steps

- [ ] Setup monitoring alerts
- [ ] Configure backups
- [ ] Restrict SSH to your IP
- [ ] Setup error notifications
- [ ] Add health check endpoint
- [ ] Configure rate limiting per endpoint
- [ ] Setup staging environment

## Support Resources

- AWS Documentation: https://docs.aws.amazon.com
- Certbot Documentation: https://certbot.eff.org
- Django Deployment: https://docs.djangoproject.com/en/stable/howto/deployment/
- Nginx Configuration: https://nginx.org/en/docs/

## Get Help

- Check logs first: `docker-compose logs`
- Check Terraform output: `terraform output`
- SSH and investigate: `ssh -i key.pem ec2-user@<IP>`
- Check AWS console for resource status
