# Latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 (for SSM, CloudWatch)
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for reading SSM parameters
resource "aws_iam_role_policy" "ec2_ssm_parameters" {
  name = "${var.project_name}-ec2-ssm-parameters"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# User data script - Complete setup with Nginx + Certbot + Redis
# Secrets are fetched from AWS Systems Manager Parameter Store
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    echo "=== Starting CineMatch Setup ==="
    
    # Get AWS region from instance metadata
    AWS_REGION="${var.aws_region}"
    PROJECT_NAME="${var.project_name}"
    ENVIRONMENT="${var.environment}"
    
    # Function to get SSM parameter
    get_ssm_param() {
      aws ssm get-parameter --name "$1" --with-decryption --region $AWS_REGION --query 'Parameter.Value' --output text
    }
    
    # Update system
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    
    # Install required packages
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      awscli \
      jq \
      dnsutils
    
    
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Install Nginx
    apt-get install -y nginx
    systemctl enable nginx
    
    # Install Certbot
    apt-get install -y python3 python3-venv libaugeas0
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install certbot certbot-nginx
    ln -sf /opt/certbot/bin/certbot /usr/bin/certbot
    
    # Create app directory
    mkdir -p /opt/cinematch
    cd /opt/cinematch
    
    echo "=== Fetching secrets from AWS SSM Parameter Store ==="
    
    # Fetch secrets from SSM (these are encrypted and never exposed in user data)
    DJANGO_SECRET=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/django-secret-key")
    DB_PASSWORD=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-password")
    DB_HOST=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-host")
    DB_NAME=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-name")
    DB_USER=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-username")
    TMDB_TOKEN=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/tmdb-token")
    LLM_KEY=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/llm-api-key")
    DOCKER_IMAGE=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/dockerhub-image")
    DOMAIN=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/domain-name")
    
    # Create .env file with fetched secrets
    cat > .env <<ENVEOF
    DEBUG=False
    SECRET_KEY=$DJANGO_SECRET
    ALLOWED_HOSTS=$DOMAIN
    
    # Database
    DB_ENGINE=django.db.backends.postgresql
    DB_NAME=$DB_NAME
    DB_USER=$DB_USER
    DB_PASSWORD=$DB_PASSWORD
    DB_HOST=$DB_HOST
    DB_PORT=5432
    
    # Redis (local on this instance)
    REDIS_URL=redis://redis:6379/1
    
    # APIs
    TMDB_READ_ACCESS_TOKEN=$TMDB_TOKEN
    LLM_API_KEY=$LLM_KEY
    LLM_API_BASE_URL=https://api.openai.com/v1
    LLM_MODEL=gpt-4o-mini
    
    # CORS
    CORS_ALLOWED_ORIGINS=https://cinematch.muhacodes.com,https://www.cinematch.muhacodes.com
    ENVEOF
    
    # Secure the .env file
    chmod 600 .env
    chown root:root .env
    
    # Create docker-compose.yml
    cat > docker-compose.yml <<DCEOF
    version: '3.8'
    services:
      redis:
        image: redis:7-alpine
        restart: always
        command: redis-server --appendonly yes
        volumes:
          - redis_data:/data
        networks:
          - cinematch
      
      web:
        image: $DOCKER_IMAGE
        ports:
          - "8000:8000"
        restart: always
        env_file:
          - .env
        command: >
          sh -c "python manage.py migrate --noinput &&
                 python manage.py collectstatic --noinput &&
                 gunicorn project.wsgi:application 
                 --bind 0.0.0.0:8000 
                 --workers 2 
                 --timeout 120"
        volumes:
          - static_volume:/app/staticfiles
        networks:
          - cinematch
        depends_on:
          - redis
    
    volumes:
      redis_data:
      static_volume:
    
    networks:
      cinematch:
        driver: bridge
    DCEOF
    
    # Configure Nginx (HTTP only initially, HTTPS after certbot)
    cat > /etc/nginx/sites-available/cinematch <<NGINXEOF
    upstream django {
      server 127.0.0.1:8000;
    }
    
    server {
        listen 80;
        server_name $DOMAIN;
        client_max_body_size 10M;
        
        location / {
            proxy_pass http://django;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_redirect off;
        }
        
        location /static/ {
            alias /opt/cinematch/staticfiles/;
        }
    }
    NGINXEOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/cinematch /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx config
    nginx -t
    
    # Start Nginx
    systemctl start nginx
    
    # Pull and run the application
    echo "=== Pulling Docker images ==="
    docker-compose pull
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 15
    
    # Setup Certbot (will run after DNS is pointed)
    cat > /root/setup-ssl.sh <<SSLEOF
    #!/bin/bash
    # Run this after DNS is pointed to this server
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@muhacodes.com --redirect
    
    # Auto-renewal
    echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | tee -a /etc/crontab > /dev/null
    SSLEOF
    chmod +x /root/setup-ssl.sh
    
    # Create update script that fetches latest secrets
    cat > /root/update-app.sh <<UPDATEEOF
    #!/bin/bash
    cd /opt/cinematch
    
    # Fetch latest secrets from SSM
    AWS_REGION="${var.aws_region}"
    PROJECT_NAME="${var.project_name}"
    ENVIRONMENT="${var.environment}"
    
    get_ssm_param() {
      aws ssm get-parameter --name "$1" --with-decryption --region $AWS_REGION --query 'Parameter.Value' --output text
    }
    
    # Update .env with latest secrets
    DJANGO_SECRET=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/django-secret-key")
    DB_PASSWORD=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-password")
    DB_HOST=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-host")
    DB_NAME=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-name")
    DB_USER=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/db-username")
    TMDB_TOKEN=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/tmdb-token")
    LLM_KEY=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/llm-api-key")
    DOCKER_IMAGE=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/dockerhub-image")
    DOMAIN=$(get_ssm_param "/$PROJECT_NAME/$ENVIRONMENT/domain-name")
    
    cat > .env <<ENVEOF2
    DEBUG=False
    SECRET_KEY=$DJANGO_SECRET
    ALLOWED_HOSTS=$DOMAIN
    DB_ENGINE=django.db.backends.postgresql
    DB_NAME=$DB_NAME
    DB_USER=$DB_USER
    DB_PASSWORD=$DB_PASSWORD
    DB_HOST=$DB_HOST
    DB_PORT=5432
    REDIS_URL=redis://redis:6379/1
    TMDB_READ_ACCESS_TOKEN=$TMDB_TOKEN
    LLM_API_KEY=$LLM_KEY
    LLM_API_BASE_URL=https://api.openai.com/v1
    LLM_MODEL=gpt-4o-mini
    CORS_ALLOWED_ORIGINS=https://cinematch.muhacodes.com,https://www.cinematch.muhacodes.com
    ENVEOF2
    
    chmod 600 .env
    
    # Update Docker image reference
    sed -i "s|image:.*|image: $DOCKER_IMAGE|g" docker-compose.yml
    
    # Pull and restart
    docker-compose pull
    docker-compose up -d
    docker-compose exec -T web python manage.py migrate --noinput
    docker-compose exec -T web python manage.py collectstatic --noinput
    docker image prune -af
    UPDATEEOF
    chmod +x /root/update-app.sh

    # Auto SSL installation script (background task)
    cat > /root/auto-ssl.sh <<EOFSSL
    #!/bin/bash

    DOMAIN="$DOMAIN"

    echo "=== Starting DNS wait for SSL ==="

    while true; do
      DOMAIN_IP=$(dig +short $DOMAIN)
      INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

      echo "Domain resolves to: \$DOMAIN_IP"
      echo "Instance IP is:    \$INSTANCE_IP"

      if [ "\$DOMAIN_IP" = "\$INSTANCE_IP" ]; then
        echo "DNS is correct. Proceeding with SSL..."
        certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@muhacodes.com --redirect
        echo "SSL setup complete."
        exit 0
      else
        echo "DNS not ready. Retrying in 60 seconds..."
        sleep 60
      fi
    done
    EOFSSL

    chmod +x /root/auto-ssl.sh
    nohup /root/auto-ssl.sh >/var/log/auto-ssl.log 2>&1 &
    
    echo "=== Setup Complete ==="
    echo "Next steps:"
    echo "1. Point $DOMAIN to this server IP"
    echo "2. Run: /root/setup-ssl.sh to setup HTTPS"
    echo "3. Visit: https://$DOMAIN/api/trending/"
  EOF
}

# EC2 Instance - Ubuntu 22.04 LTS
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_type
  key_name               = var.ec2_key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  tags = {
    Name = "${var.project_name}-app-server"
  }
}

# Elastic IP for EC2 (static IP address)
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-app-eip"
  }
}
