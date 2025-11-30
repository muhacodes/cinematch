#!/bin/bash
set -e

apt update -y
apt install -y docker.io docker-compose awscli

systemctl enable docker
systemctl start docker

AWS_REGION="eu-west-2"
PROJECT="cinematch"
ENV="production"

get_param() {
  aws ssm get-parameter --name "/$PROJECT/$ENV/$1" --with-decryption --region $AWS_REGION --query 'Parameter.Value' --output text
}

IMAGE=$(get_param "dockerhub-image")
DJANGO_SECRET=$(get_param "django-secret-key")
DB_HOST=$(get_param "db-host")
DB_NAME=$(get_param "db-name")
DB_USER=$(get_param "db-username")
DB_PASS=$(get_param "db-password")
TMDB=$(get_param "tmdb-token")
LLM=$(get_param "llm-api-key")

mkdir -p /app
cd /app

cat > .env <<EOF
SECRET_KEY=$DJANGO_SECRET
DEBUG=False

DB_ENGINE=django.db.backends.postgresql
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_HOST=$DB_HOST
DB_PORT=5432

REDIS_URL=redis://redis:6379/1

TMDB_READ_ACCESS_TOKEN=$TMDB
LLM_API_KEY=$LLM
LLM_API_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini
EOF

cat > docker-compose.yml <<EOF
version: "3.8"

services:
  redis:
    image: redis:7-alpine
    restart: always

  web:
    image: $IMAGE
    restart: always
    env_file: .env
    ports:
      - "8000:8000"
    command: >
      sh -c "
      python manage.py migrate --noinput &&
      python manage.py collectstatic --noinput &&
      gunicorn project.wsgi:application --bind 0.0.0.0:8000
      "
    depends_on:
      - redis
EOF

docker-compose pull
docker-compose up -d
