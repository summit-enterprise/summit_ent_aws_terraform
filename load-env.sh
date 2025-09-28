#!/bin/bash
# ========================================
# ENVIRONMENT VARIABLES LOADER
# ========================================
# This script loads environment variables from .env file
# Usage: source load-env.sh

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📋 Please copy env.template to .env and fill in your values:"
    echo "   cp env.template .env"
    echo "   nano .env"
    exit 1
fi

# Load environment variables
echo "🔧 Loading environment variables from .env file..."

# Load simple key=value pairs (skip arrays and comments)
set -a
source .env
set +a

# Handle array variables separately
export AVAILABILITY_ZONES='["us-east-2a", "us-east-2b"]'
export PUBLIC_SUBNET_CIDRS='["10.0.1.0/24", "10.0.2.0/24"]'
export PRIVATE_SUBNET_CIDRS='["10.0.10.0/24", "10.0.20.0/24"]'

# Verify required variables are set
if [ -z "$AWS_DEFAULT_REGION" ]; then
    echo "❌ Missing required variable: AWS_DEFAULT_REGION"
    exit 1
fi

if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Missing required variable: ENVIRONMENT"
    exit 1
fi

if [ -z "$VPC_CIDR" ]; then
    echo "❌ Missing required variable: VPC_CIDR"
    exit 1
fi

echo "✅ Environment variables loaded successfully!"
echo "🌍 Current environment: $ENVIRONMENT"
echo "🌎 AWS Region: $AWS_DEFAULT_REGION"
echo "🏗️  VPC CIDR: $VPC_CIDR"