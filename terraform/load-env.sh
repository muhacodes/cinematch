#!/bin/bash
# Script to load environment variables from .env file for Terraform
# Usage: source ./load-env.sh

set -a
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    source .env
    echo "✅ Environment variables loaded!"
    echo "Run terraform plan/apply to use them."
else
    echo "❌ Error: .env file not found!"
    echo "Copy .env.example to .env and fill in your values:"
    echo "  cp .env.example .env"
    exit 1
fi
set +a

