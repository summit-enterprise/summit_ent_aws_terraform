#!/bin/bash

# ========================================
# MODULE MANAGEMENT SCRIPT
# ========================================
# This script helps manage all Terraform modules from one place

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the parent directory (one level up)
PARENT_DIR="$(cd .. && pwd)"
MODULES_DIR="$PARENT_DIR"

# List of all modules
MODULES=(
    "terraform-aws-networking"
    "terraform-aws-security"
    "terraform-aws-storage"
    "terraform-aws-compute"
    "terraform-aws-monitoring"
    "terraform-aws-secrets"
)

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

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "main.tf" ]; then
        print_error "Please run this script from the aws-summit-terraform directory"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Terraform Module Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status          Show status of all modules"
    echo "  pull            Pull latest changes from all modules"
    echo "  push            Push changes to all modules"
    echo "  commit MESSAGE  Commit changes in all modules with message"
    echo "  tag VERSION     Create and push tags for all modules"
    echo "  update          Update all modules to latest versions"
    echo "  diff            Show differences in all modules"
    echo "  clean           Clean untracked files in all modules"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 pull"
    echo "  $0 commit 'feat: add new feature'"
    echo "  $0 tag v1.2.0"
}

# Function to run command in all modules
run_in_all_modules() {
    local command="$1"
    local args="$2"
    
    print_status "Running '$command' in all modules..."
    echo ""
    
    for module in "${MODULES[@]}"; do
        local module_path="$MODULES_DIR/$module"
        
        if [ -d "$module_path" ]; then
            echo -e "${BLUE}📁 $module${NC}"
            cd "$module_path"
            
            if [ -n "$args" ]; then
                eval "$command $args"
            else
                eval "$command"
            fi
            
            echo ""
        else
            print_warning "Module $module not found at $module_path"
        fi
    done
    
    cd "$(pwd)"
}

# Function to show status of all modules
show_status() {
    print_status "Checking status of all modules..."
    echo ""
    
    for module in "${MODULES[@]}"; do
        local module_path="$MODULES_DIR/$module"
        
        if [ -d "$module_path" ]; then
            echo -e "${BLUE}📁 $module${NC}"
            cd "$module_path"
            
            # Check if it's a git repository
            if [ -d ".git" ]; then
                # Show current branch
                local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
                echo "  Branch: $branch"
                
                # Show status
                local status=$(git status --porcelain 2>/dev/null)
                if [ -n "$status" ]; then
                    echo "  Status: Has uncommitted changes"
                    echo "$status" | sed 's/^/    /'
                else
                    echo "  Status: Clean"
                fi
                
                # Show last commit
                local last_commit=$(git log -1 --oneline 2>/dev/null || echo "No commits")
                echo "  Last commit: $last_commit"
            else
                echo "  Status: Not a git repository"
            fi
            
            echo ""
        else
            print_warning "Module $module not found at $module_path"
        fi
    done
}

# Function to pull latest changes
pull_all() {
    run_in_all_modules "git pull origin main"
    print_success "All modules updated!"
}

# Function to push changes
push_all() {
    run_in_all_modules "git push origin main"
    print_success "All modules pushed!"
}

# Function to commit changes
commit_all() {
    local message="$1"
    
    if [ -z "$message" ]; then
        print_error "Please provide a commit message"
        echo "Usage: $0 commit 'Your commit message'"
        exit 1
    fi
    
    run_in_all_modules "git add . && git commit -m \"$message\""
    print_success "All modules committed with message: '$message'"
}

# Function to create and push tags
tag_all() {
    local version="$1"
    
    if [ -z "$version" ]; then
        print_error "Please provide a version number"
        echo "Usage: $0 tag v1.2.0"
        exit 1
    fi
    
    run_in_all_modules "git tag $version && git push origin $version"
    print_success "All modules tagged with version: $version"
}

# Function to show differences
diff_all() {
    run_in_all_modules "git diff"
}

# Function to clean untracked files
clean_all() {
    run_in_all_modules "git clean -fd"
    print_success "All modules cleaned!"
}

# Main script logic
check_directory

case "${1:-help}" in
    "status")
        show_status
        ;;
    "pull")
        pull_all
        ;;
    "push")
        push_all
        ;;
    "commit")
        commit_all "$2"
        ;;
    "tag")
        tag_all "$2"
        ;;
    "diff")
        diff_all
        ;;
    "clean")
        clean_all
        ;;
    "help"|*)
        show_help
        ;;
esac
