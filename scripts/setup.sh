#!/bin/bash

# Claude Code Docker Environment Setup Script
# Supports Ubuntu/Debian, CentOS/RHEL/Rocky, macOS

set -e

echo "=== Claude Code Docker Environment Setup ==="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        elif [ -f /etc/redhat-release ]; then
            OS="centos"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    log_info "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install packages to allow apt to use a repository over HTTPS
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Install docker-compose (standalone)
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Install Docker on CentOS/RHEL/Rocky
install_docker_centos() {
    log_info "Installing Docker on CentOS/RHEL/Rocky..."
    
    # Remove old versions
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    
    # Install yum-utils
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Install docker-compose (standalone)
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Install Docker on macOS
install_docker_macos() {
    log_info "Installing Docker on macOS..."
    
    if command_exists brew; then
        log_info "Using Homebrew to install Docker Desktop..."
        brew install --cask docker
        log_warning "Please start Docker Desktop manually from Applications folder"
    else
        log_error "Homebrew not found. Please install Docker Desktop manually:"
        log_info "1. Download from: https://docs.docker.com/desktop/mac/install/"
        log_info "2. Install Docker Desktop"
        log_info "3. Start Docker Desktop"
        return 1
    fi
}

# Install Docker Compose manually
install_docker_compose_manual() {
    log_info "Installing Docker Compose manually..."
    
    # Get latest version
    local latest_version
    if command_exists curl; then
        latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    else
        latest_version="v2.24.1"  # Fallback version
        log_warning "curl not available, using fallback version $latest_version"
    fi
    
    # Download and install
    local compose_url="https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-$(uname -s)-$(uname -m)"
    
    if sudo curl -L "$compose_url" -o /usr/local/bin/docker-compose; then
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Create symlink in user's local bin if it exists
        if [ -d "$HOME/.local/bin" ]; then
            ln -sf /usr/local/bin/docker-compose "$HOME/.local/bin/docker-compose"
        fi
        
        # Verify installation
        if command_exists docker-compose; then
            log_success "Docker Compose installed: $(docker-compose --version)"
            return 0
        else
            log_warning "Docker Compose installed but not in PATH"
            log_info "You may need to add /usr/local/bin to your PATH"
            return 0
        fi
    else
        log_error "Failed to download Docker Compose"
        return 1
    fi
}

# Setup Docker permissions (Linux only)
setup_docker_permissions() {
    if [[ "$OS" != "linux-gnu"* ]] && [[ "$OS" != "ubuntu" ]] && [[ "$OS" != "debian" ]] && [[ "$OS" != "centos" ]] && [[ "$OS" != "rhel" ]] && [[ "$OS" != "rocky" ]]; then
        return 0
    fi
    
    log_info "Setting up Docker permissions..."
    
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null 2>&1; then
        sudo groupadd docker
    fi
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_warning "You need to log out and log back in (or run 'newgrp docker') for group changes to take effect"
}

# Verify Docker installation
verify_docker() {
    log_info "Verifying Docker installation..."
    
    if command_exists docker; then
        log_success "Docker is installed: $(docker --version)"
    else
        log_error "Docker installation failed"
        return 1
    fi
    
    # Check for docker-compose or docker compose plugin
    local compose_available=false
    
    if command_exists docker-compose; then
        log_success "Docker Compose is installed: $(docker-compose --version)"
        compose_available=true
    elif docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose (plugin) is installed: $(docker compose version)"
        compose_available=true
    else
        log_warning "Docker Compose not found, attempting to install..."
        
        # Try to install docker-compose manually
        if install_docker_compose_manual; then
            compose_available=true
        fi
    fi
    
    if [ "$compose_available" = false ]; then
        log_error "Docker Compose installation failed"
        log_info "Please install Docker Compose manually using:"
        log_info "./install-compose.sh"
        log_info "Or follow: https://docs.docker.com/compose/install/"
        return 1
    fi
    
    # Test Docker daemon (skip on macOS if Docker Desktop not running)
    if [[ "$OS" != "macos" ]]; then
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon is running"
        else
            log_warning "Docker daemon is not running or not accessible"
            log_info "Try: sudo systemctl start docker"
            log_info "Or run 'newgrp docker' if you just added user to docker group"
        fi
    fi
}

# Setup environment file
setup_environment() {
    log_info "Setting up environment file..."
    
    if [ ! -f .env ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_warning "Please edit .env file and add your ANTHROPIC_API_KEY"
    else
        log_info ".env file already exists"
    fi
}

# Main installation function
main() {
    log_info "Starting Claude Code Docker Environment setup..."
    
    # Detect OS
    detect_os
    log_info "Detected OS: $OS"
    
    # Check if Docker is already installed
    if command_exists docker; then
        log_info "Docker is already installed"
        verify_docker
    else
        case "$OS" in
            ubuntu|debian)
                install_docker_ubuntu
                ;;
            centos|rhel|rocky)
                install_docker_centos
                ;;
            macos)
                install_docker_macos
                ;;
            windows)
                log_error "Windows detected. Please install Docker Desktop manually:"
                log_info "https://docs.docker.com/desktop/windows/install/"
                exit 1
                ;;
            *)
                log_error "Unsupported OS: $OS"
                log_info "Please install Docker manually:"
                log_info "https://docs.docker.com/engine/install/"
                exit 1
                ;;
        esac
        
        # Setup permissions (Linux only)
        setup_docker_permissions
        
        # Verify installation
        verify_docker
    fi
    
    # Setup environment
    setup_environment
    
    echo
    log_success "Setup completed!"
    echo
    echo "Next steps:"
    echo "1. Edit .env file and add your ANTHROPIC_API_KEY"
    echo "2. Run: ./test-local.sh (to validate configuration)"
    echo "3. Run: docker-compose up -d --build (to start the environment)"
    echo "4. Run: docker-compose exec claude-dev bash (to enter the container)"
    echo "5. Run: claude (to start Claude Code)"
    echo
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]] || [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]]; then
        log_warning "If you get permission errors, you may need to:"
        log_info "- Log out and log back in, OR"
        log_info "- Run: newgrp docker"
    fi
    
    if [[ "$OS" == "macos" ]]; then
        log_warning "Make sure Docker Desktop is running before proceeding"
    fi
}

# Run main function
main "$@"