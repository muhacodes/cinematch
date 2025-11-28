# CineMatch - Quick Start Deployment

Deploy in **10 minutes** with 1 EC2 instance, Nginx, and FREE SSL!

## What You'll Get

```
✅ Single t2.micro EC2 (~$8/month, FREE for 12 months)
✅ RDS PostgreSQL (~$12/month, FREE for 12 months)  
✅ Redis inside EC2(FREE!)
✅ Nginx reverse proxy (FREE!)
✅ SSL certificate from Let's Encrypt (FREE!)
✅ Domain: api.cinematch.muhacodes.com
```

**Total cost: $0 first year, ~$20/month after**

## Prerequisites (5 min)

1. **AWS Account** - https://aws.amazon.com
2. **AWS CLI** - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
3. **Terraform** - https://developer.hashicorp.com/terraform/downloads
4. **DockerHub Account** - https://hub.docker.com
5. **EC2 Key Pair** - Create in AWS Console

## Deployment (10 min)

### 1. Configure (2 min)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Update these 3 critical values:
```hcl
ec2_key_name    = "your-key-name"      # Your EC2 key
db_password     = "YourStrongPass123!" # Database password
dockerhub_image = "yourusername/cinematch:latest"
```

### 2. Build & Push Image (3 min)

```bash
# Build
docker build -f Dockerfile.prod -t yourusername/cinematch:latest .

# Push
docker login
docker push yourusername/cinematch:latest
```

### 3. Deploy to AWS (5 min)

```bash
cd terraform
terraform init
terraform apply  # Type 'yes' when prompted
```

Wait ~5 minutes. Note the IP address from output.

### 4. Setup DNS (2 min)

In your DNS provider (muhacodes.com):

```
Type: A
Name: api.cinematch  
Value: <EC2_IP_FROM_TERRAFORM>
TTL: 300
```

Wait 5-10 minutes for DNS to propagate.

### 5. Get FREE SSL (1 min)

```bash
# Get the IP
terraform output ec2_public_ip

# SSH and setup SSL
ssh -i your-key.pem ec2-user@<EC2_IP>
sudo /root/setup-ssl.sh
```

Done! 🎉

## Test It

```bash
curl https://api.cinematch.muhacodes.com/api/trending/
curl https://api.cinematch.muhacodes.com/api/genres/
```

## Update App

```bash
# Build new version
docker build -f Dockerfile.prod -t yourusername/cinematch:latest .
docker push yourusername/cinematch:latest

# Update on server
ssh -i your-key.pem ec2-user@<EC2_IP> 'sudo /root/update-app.sh'
```

## Useful Commands

```bash
# SSH to server
ssh -i your-key.pem ec2-user@<EC2_IP>

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Check status
docker-compose ps
```

## Troubleshooting

**DNS not working?**
```bash
nslookup api.cinematch.muhacodes.com
# Wait 10 more minutes if not resolving
```

**SSL fails?**
```bash
# Check Nginx is running
sudo systemctl status nginx

# Try manual
sudo certbot --nginx -d api.cinematch.muhacodes.com
```

**App not starting?**
```bash
docker-compose logs web
cat .env  # Check environment variables
```

## Auto-Deployment (Optional)

Add these secrets to GitHub:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`  
- `EC2_HOST` (your EC2 IP)
- `EC2_SSH_PRIVATE_KEY` (your .pem file content)

Push to `main` = auto-deploy! 🚀

## Clean Up

```bash
terraform destroy  # Deletes everything
```

## Cost

| Resource | Monthly | First Year (Free Tier) |
|----------|---------|------------------------|
| EC2 t2.micro | $8-10 | FREE |
| RDS db.t3.micro | $12-15 | FREE |
| Redis | $0 | $0 |
| SSL | $0 | $0 |
| **Total** | **~$20-25** | **~$0** |

## What's Running

On your EC2 instance:
- **Nginx** - Web server, reverse proxy, SSL termination
- **Docker Containers:**
  - Django app (port 8000)
  - Redis cache (port 6379)
- **Certbot** - Auto-renews SSL certificate

On RDS:
- **PostgreSQL** - Private, only accessible from EC2

## Architecture

```
Internet → Nginx (443) → Django (8000) → RDS (5432)
                      ↓
                   Redis (6379)
```

Simple, clean, cheap! 💪

## Full Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [terraform/README.md](terraform/README.md) - Terraform details  
- [README.md](README.md) - Full project documentation

## Support

1. Check logs: `docker-compose logs`
2. SSH and investigate: `ssh -i key.pem ec2-user@<IP>`
3. Review [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting

