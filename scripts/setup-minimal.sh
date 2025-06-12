#!/bin/bash

# Minimal setup script for environments with limited permissions
# This script only sets up the environment file and validates configuration

echo "=== Claude Code Docker Environment - Minimal Setup ==="
echo "This script is for environments where Docker is already installed"
echo "or where you don't have sudo permissions."
echo

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup environment file
setup_environment() {
    log_info "Setting up environment file..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            log_success "Created .env file from template"
            log_warning "Please edit .env file and add your ANTHROPIC_API_KEY"
        else
            log_warning ".env.example file not found, creating basic .env"
            cat > .env << EOF
# Claude API Configuration
ANTHROPIC_API_KEY=your_api_key_here

# Optional: Specify Claude model
# ANTHROPIC_MODEL=claude-3-5-sonnet

# Development Environment
COMPOSE_PROJECT_NAME=claude-dev
EOF
            log_success "Created basic .env file"
            log_warning "Please edit .env file and add your ANTHROPIC_API_KEY"
        fi
    else
        log_info ".env file already exists"
    fi
}

# Check Docker availability
check_docker() {
    log_info "Checking Docker availability..."
    
    if command_exists docker; then
        log_success "Docker is available: $(docker --version)"
        
        # Test Docker daemon access
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon is accessible"
        else
            log_warning "Docker daemon is not accessible"
            log_info "You may need to:"
            log_info "- Add your user to docker group: sudo usermod -aG docker \$USER"
            log_info "- Restart your terminal session"
            log_info "- Or run Docker commands with sudo"
        fi
    else
        log_warning "Docker is not installed or not in PATH"
        log_info "Please install Docker first:"
        log_info "- Ubuntu/Debian: ./setup.sh"
        log_info "- macOS: brew install --cask docker"
        log_info "- Windows: Download Docker Desktop"
    fi
    
    if command_exists docker-compose; then
        log_success "Docker Compose is available: $(docker-compose --version)"
    elif docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose (plugin) is available"
    else
        log_warning "Docker Compose is not available"
        log_info "Please install Docker Compose"
    fi
}

# Validate configuration files
validate_config() {
    log_info "Validating configuration files..."
    
    # Check required files
    required_files=("Dockerfile" "docker-compose.yml" "claude-config/settings.json")
    all_good=true
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "$file exists"
        else
            log_warning "$file is missing"
            all_good=false
        fi
    done
    
    # Validate JSON if python is available
    if command_exists python3 && [ -f "claude-config/settings.json" ]; then
        if python3 -m json.tool claude-config/settings.json >/dev/null 2>&1; then
            log_success "settings.json has valid JSON syntax"
        else
            log_warning "settings.json has invalid JSON syntax"
            all_good=false
        fi
    fi
    
    if $all_good; then
        log_success "All configuration files are valid"
    else
        log_warning "Some configuration issues found"
    fi
}

# Main function
main() {
    setup_environment
    echo
    check_docker
    echo
    validate_config
    echo
    
    log_success "Minimal setup completed!"
    echo
    echo "Next steps:"
    echo "1. Edit .env file and add your ANTHROPIC_API_KEY"
    echo "2. If Docker is available:"
    echo "   - Run: ./test-local.sh (configuration validation)"
    echo "   - Run: docker-compose up -d --build"
    echo "   - Run: docker-compose exec claude-dev bash"
    echo "   - Run: claude"
    echo "3. If Docker is not available:"
    echo "   - Install Docker using ./setup.sh (Linux/macOS)"
    echo "   - Or install Docker Desktop manually"
    echo
}

main "$@"