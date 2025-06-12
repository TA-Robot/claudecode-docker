#!/bin/bash

# Docker Compose installation script (requires sudo)
# Run this separately if setup.sh fails with Docker Compose installation

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "=== Docker Compose Installation ==="
echo

# Check if already installed
if command_exists docker-compose; then
    log_success "Docker Compose is already installed: $(docker-compose --version)"
    exit 0
elif docker compose version >/dev/null 2>&1; then
    log_success "Docker Compose (plugin) is already installed: $(docker compose version)"
    exit 0
fi

log_info "Installing Docker Compose..."

# Method 1: Try to install via package manager
if command_exists apt-get; then
    log_info "Attempting installation via apt..."
    if sudo apt-get update && sudo apt-get install -y docker-compose; then
        log_success "Docker Compose installed via apt"
        docker-compose --version
        exit 0
    else
        log_warning "apt installation failed, trying manual installation..."
    fi
fi

# Method 2: Manual installation
log_info "Installing Docker Compose manually..."

# Get latest version
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$COMPOSE_VERSION" ]; then
    COMPOSE_VERSION="v2.24.1"
    log_warning "Failed to get latest version, using fallback: $COMPOSE_VERSION"
fi

log_info "Installing Docker Compose $COMPOSE_VERSION..."

# Download and install
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"

if sudo curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose; then
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for user
    if [ -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/local/bin/docker-compose "$HOME/.local/bin/docker-compose"
    fi
    
    # Update PATH if needed
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
        log_info "Added /usr/local/bin to PATH in ~/.bashrc"
    fi
    
    # Verify installation
    if /usr/local/bin/docker-compose --version >/dev/null 2>&1; then
        log_success "Docker Compose installed successfully!"
        /usr/local/bin/docker-compose --version
        
        log_warning "You may need to restart your terminal or run:"
        log_info "source ~/.bashrc"
        log_info "Or use the full path: /usr/local/bin/docker-compose"
    else
        log_error "Installation verification failed"
        exit 1
    fi
else
    log_error "Failed to download Docker Compose"
    log_info "Please install manually following: https://docs.docker.com/compose/install/"
    exit 1
fi

echo
log_success "Docker Compose installation completed!"
echo "You can now run: ./setup.sh"