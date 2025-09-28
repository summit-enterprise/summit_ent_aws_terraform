#!/bin/bash
# ========================================
# ENVIRONMENT SETUP SCRIPT
# ========================================
# This script sets up your environment variables

echo "🔧 Setting up environment variables..."

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

# Copy template to .env
cp env.template .env

echo "✅ Created .env file from template"
echo "📝 Please edit .env file with your actual values:"
echo "   nano .env"
echo "   code .env"
echo "   vim .env"
echo ""
echo "🔑 Required variables to set:"
echo "   - AWS_ACCESS_KEY_ID (if not using IAM roles)"
echo "   - AWS_SECRET_ACCESS_KEY (if not using IAM roles)"
echo ""
echo "🚀 After editing .env, load variables with:"
echo "   source load-env.sh"
