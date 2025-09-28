#!/bin/bash

# Terraform Module Publishing Script
# This script helps you publish your Terraform modules to GitHub and Terraform Registry

set -e

# Configuration
GITHUB_USERNAME="summit-enterprise"  # Replace with your GitHub username
MODULES_DIR="terraform/modules"
GITHUB_ORG=""  # Leave empty for personal account, or set to your organization

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first:"
        echo "  macOS: brew install gh"
        echo "  Linux: https://github.com/cli/cli/releases"
        echo "  Windows: https://github.com/cli/cli/releases"
        exit 1
    fi
    
    # Check if user is logged in
    if ! gh auth status &> /dev/null; then
        print_error "You are not logged in to GitHub CLI. Please run: gh auth login"
        exit 1
    fi
}

# Function to create versions.tf if it doesn't exist
create_versions_tf() {
    local module_dir=$1
    local versions_file="$module_dir/versions.tf"
    
    if [ ! -f "$versions_file" ]; then
        print_status "Creating versions.tf for $module_dir"
        cat > "$versions_file" << EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
    fi
}

# Function to create basic README.md if it doesn't exist
create_basic_readme() {
    local module_dir=$1
    local module_name=$(basename "$module_dir")
    local readme_file="$module_dir/README.md"
    
    if [ ! -f "$readme_file" ]; then
        print_status "Creating basic README.md for $module_name"
        cat > "$readme_file" << EOF
# terraform-aws-$module_name

A Terraform module for AWS $module_name infrastructure.

## Usage

\`\`\`hcl
module "$module_name" {
  source = "$GITHUB_USERNAME/$module_name/aws"
  version = "1.0.0"
  
  # Add your variables here
}
\`\`\`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## License

MIT
EOF
    fi
}

# Function to publish a single module
publish_module() {
    local module_name=$1
    local module_dir="$MODULES_DIR/$module_name"
    local repo_name="terraform-aws-$module_name"
    
    print_status "Publishing module: $module_name"
    
    # Check if module directory exists
    if [ ! -d "$module_dir" ]; then
        print_error "Module directory $module_dir does not exist"
        return 1
    fi
    
    # Create versions.tf if it doesn't exist
    create_versions_tf "$module_dir"
    
    # Create basic README.md if it doesn't exist
    create_basic_readme "$module_dir"
    
    # Create GitHub repository
    print_status "Creating GitHub repository: $repo_name"
    
    if [ -n "$GITHUB_ORG" ]; then
        gh repo create "$GITHUB_ORG/$repo_name" --public --description "AWS $module_name Terraform Module"
        REPO_URL="https://github.com/$GITHUB_ORG/$repo_name.git"
    else
        gh repo create "$repo_name" --public --description "AWS $module_name Terraform Module"
        REPO_URL="https://github.com/$GITHUB_USERNAME/$repo_name.git"
    fi
    
    # Clone the repository
    print_status "Cloning repository..."
    git clone "$REPO_URL" "/tmp/$repo_name"
    
    # Copy module files
    print_status "Copying module files..."
    cp -r "$module_dir"/* "/tmp/$repo_name/"
    
    # Navigate to repository directory
    cd "/tmp/$repo_name"
    
    # Initialize git repository
    git add .
    git commit -m "Initial commit: AWS $module_name module"
    git push origin main
    
    # Create version tag
    print_status "Creating version tag v1.0.0..."
    git tag -a v1.0.0 -m "Version 1.0.0"
    git push origin v1.0.0
    
    # Clean up
    cd - > /dev/null
    rm -rf "/tmp/$repo_name"
    
    print_success "Module $module_name published successfully!"
    print_status "Repository: $REPO_URL"
    print_status "Next step: Publish to Terraform Registry at https://app.terraform.io/"
}

# Function to publish all modules
publish_all_modules() {
    print_status "Publishing all modules..."
    
    for module_dir in "$MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            module_name=$(basename "$module_dir")
            publish_module "$module_name"
            echo ""
        fi
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [MODULE_NAME]"
    echo ""
    echo "Options:"
    echo "  -a, --all        Publish all modules"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 networking                    # Publish only the networking module"
    echo "  $0 --all                        # Publish all modules"
    echo ""
    echo "Available modules:"
    for module_dir in "$MODULES_DIR"/*; do
        if [ -d "$module_dir" ]; then
            echo "  - $(basename "$module_dir")"
        fi
    done
}

# Main script
main() {
    # Check if GitHub CLI is installed and user is logged in
    check_gh_cli
    
    # Parse command line arguments
    case "${1:-}" in
        -a|--all)
            publish_all_modules
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            publish_module "$1"
            ;;
    esac
}

# Run main function
main "$@"
