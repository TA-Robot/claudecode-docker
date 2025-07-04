#!/bin/bash

# Claude Code Docker Environment Management Script
# Main script for managing the development environment

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Auto-detect Docker GID at script start
if [ -z "$DOCKER_GID" ]; then
    export DOCKER_GID=$(stat -c %g /var/run/docker.sock 2>/dev/null || echo "999")
fi

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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Get project name from .project-name file or directory name
get_project_name() {
    local project_name=""
    
    # Check if .project-name file exists in projects directory
    if [ -f "./projects/.project-name" ]; then
        project_name=$(cat ./projects/.project-name | tr -d '\n' | tr -d '\r')
    fi
    
    # If empty or not found, use current directory name
    if [ -z "$project_name" ]; then
        project_name=$(basename "$(pwd)")
    fi
    
    # Sanitize project name for Docker (lowercase, alphanumeric and hyphens only)
    project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^-*//' | sed 's/-*$//')
    
    # Ensure project name is not empty
    if [ -z "$project_name" ]; then
        project_name="default"
    fi
    
    echo "$project_name"
}

# This function is no longer needed as we use docker-compose.yml directly
# Kept for backward compatibility but does nothing
generate_dynamic_compose() {
    log_info "Using docker-compose.yml directly (no generation needed)"
    echo "docker-compose.yml"
}

# Check if Docker Compose is available
get_compose_cmd() {
    # Set project name based on current directory path
    local dir_hash=$(pwd | sha256sum | cut -c1-8)
    local project_name="claude-${dir_hash}"
    export COMPOSE_PROJECT_NAME="$project_name"
    
    # DOCKER_GID is already set at script start
    
    if command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose -p $project_name"
    elif docker compose version >/dev/null 2>&1; then
        echo "docker compose -p $project_name"
    else
        log_error "Docker Compose not found. Please run ./setup.sh first"
        exit 1
    fi
}

# Copy credentials from host to container mount
copy_credentials() {
    if [[ -f "$HOME/.claude/.credentials.json" ]]; then
        log_info "Copying Claude credentials..."
        mkdir -p ./claude-config
        cp "$HOME/.claude/.credentials.json" ./claude-config/.credentials.json
        chmod 600 ./claude-config/.credentials.json
        log_success "Credentials copied successfully"
    else
        log_info "No credentials found at $HOME/.claude/.credentials.json"
    fi
}

# Create docker-compose override file based on credentials availability
create_compose_override() {
    # Note: Override functionality is now handled by explicit -f flags in get_compose_cmd
    # This function is kept for backward compatibility but doesn't create override files
    if [[ -f "./claude-config/.credentials.json" ]]; then
        log_info "Credentials found, will be mounted via generated compose file"
    else
        log_info "No credentials found at ./claude-config/.credentials.json"
    fi
}

# Show help
show_help() {
    log_header "=== Claude Code Docker Environment Management ==="
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  setup     - Run initial setup (same as ./setup.sh)"
    echo "  start     - Start the development environment"
    echo "  stop      - Stop the development environment"
    echo "  restart   - Restart the development environment"
    echo "  shell     - Enter the container shell"
    echo "  claude    - Start Claude Code in the container"
    echo "  gemini    - Start Gemini CLI in the container"
    echo "  logs      - Show container logs"
    echo "  status    - Show container status"
    echo "  build     - Build/rebuild the container"
    echo "  clean     - Clean up containers and images"
    echo "  test      - Run configuration tests"
    echo "  env       - Check environment setup"
    echo "  help      - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start        # Start the environment"
    echo "  $0 shell        # Enter container for development"
    echo "  $0 claude       # Start Claude Code directly"
    echo
}

# Setup environment
setup_env() {
    log_info "Running setup..."
    if [ -f "./scripts/setup.sh" ]; then
        ./scripts/setup.sh
    else
        ./setup.sh
    fi
    
    # Copy credentials if exists
    copy_credentials
}

# Automatically rebuild image if Dockerfile changed
rebuild_if_dockerfile_changed() {
    local compose_cmd=$(get_compose_cmd)
    local checksum_file=".dockerfile.sha256"

    # Dockerfile が無い場合は何もしない
    if [ ! -f Dockerfile ]; then
        return
    fi

    # 現在のハッシュを計算
    local current_checksum=$(sha256sum Dockerfile | awk '{print $1}')

    # 以前のハッシュを取得（無ければ空）
    local saved_checksum=""
    if [ -f "$checksum_file" ]; then
        saved_checksum=$(cat "$checksum_file")
    fi

    # ハッシュが変わっていれば再ビルド
    if [ "$current_checksum" != "$saved_checksum" ]; then
        log_info "Dockerfile の変更を検知しました。共通イメージを再ビルドします..."
        #$compose_cmd build --no-cache
        $compose_cmd build 
        echo "$current_checksum" > "$checksum_file"
        log_success "共通イメージを再ビルドしました！"
    fi
}

# Start environment
start_env() {
    local compose_cmd=$(get_compose_cmd)
    
    # Show Docker GID info
    log_info "Using Docker GID: $DOCKER_GID"
    
    # Dockerfile 変更チェック
    rebuild_if_dockerfile_changed
    
    log_info "Starting Claude Code development environment..."
    
    # Check if .env exists
    if [ ! -f .env ]; then
        log_warning ".env file not found"
        if [ -f .env.example ]; then
            log_info "Creating .env from template..."
            cp .env.example .env
            log_warning "Please edit .env and add your ANTHROPIC_API_KEY"
            log_info "Then run: $0 start"
            exit 1
        else
            log_error ".env.example not found"
            exit 1
        fi
    fi
    
    # Check for API key
    if ! grep -q "ANTHROPIC_API_KEY=" .env || grep -q "your_api_key_here" .env; then
        log_warning "ANTHROPIC_API_KEY not configured in .env"
        log_info "Please edit .env and add your API key, then restart"
    fi
    
    # Copy credentials before starting
    copy_credentials
    
    # Create override file based on credentials
    create_compose_override
    
    $compose_cmd up -d
    log_success "Environment started!"
    log_info "Use '$0 shell' to enter the container"
    log_info "Use '$0 claude' to start Claude Code directly"
}

# Stop environment
stop_env() {
    local compose_cmd=$(get_compose_cmd)
    
    log_info "Stopping Claude Code development environment..."
    $compose_cmd down
    log_success "Environment stopped!"
}

# Restart environment
restart_env() {
    log_info "Restarting environment..."
    stop_env
    start_env
}

# Enter shell
enter_shell() {
    local compose_cmd=$(get_compose_cmd)
    local project_name=$(get_project_name)
    
    # Check if container is running
    if ! $compose_cmd ps | grep -q "claude-dev.*Up"; then
        log_warning "Container is not running. Starting environment..."
        start_env
        sleep 2
    fi
    
    log_info "Entering container shell for project: $project_name"
    log_info "You are now in /workspace/projects"
    log_info "Run 'claude' to start Claude Code"
    echo
    $compose_cmd exec -u 1000 claude-dev zsh
}

# Start Claude Code directly
start_claude() {
    local compose_cmd=$(get_compose_cmd)
    local project_name=$(get_project_name)
    
    # Check if container is running
    if ! $compose_cmd ps | grep -q "claude-dev.*Up"; then
        log_warning "Container is not running. Starting environment..."
        start_env
        sleep 2
    fi
    
    log_info "Starting Claude Code for project: $project_name"
    $compose_cmd exec -u 1000 claude-dev claude --dangerously-skip-permissions
}

# Start Gemini CLI directly
start_gemini() {
    local compose_cmd=$(get_compose_cmd)
    local project_name=$(get_project_name)
    
    # Check if container is running
    if ! $compose_cmd ps | grep -q "claude-dev.*Up"; then
        log_warning "Container is not running. Starting environment..."
        start_env
        sleep 2
    fi

    # Copy Gemini credentials from host to container as a temporary fix
    if [ -d "$HOME/.gemini" ]; then
        log_info "Copying Gemini credentials from host to container..."
        # Get container ID
        local container_id=$($compose_cmd ps -q claude-dev)
        if [ -n "$container_id" ]; then
            # Remove existing .gemini dir in container to ensure a clean copy
            $compose_cmd exec -u 0 claude-dev rm -rf /home/developer/.gemini
            # Copy from host to container
            docker cp "$HOME/.gemini" "$container_id:/home/developer/.gemini"
            # Fix permissions
            $compose_cmd exec -u 0 claude-dev chown -R 1000:1000 /home/developer/.gemini
            log_success "Gemini credentials copied."
        else
            log_error "Could not find the claude-dev container."
        fi
    else
        log_warning "Host Gemini credentials not found at ~/.gemini. Skipping copy."
    fi
    
    log_info "Starting Gemini CLI for project: $project_name"
    $compose_cmd exec -u 1000 claude-dev gemini --debug
}

# Show logs
show_logs() {
    local compose_cmd=$(get_compose_cmd)
    
    log_info "Showing container logs (Ctrl+C to exit)..."
    $compose_cmd logs -f claude-dev
}

# Show status
show_status() {
    local compose_cmd=$(get_compose_cmd)
    local project_name=$(get_project_name)
    
    log_info "Container status for project: $project_name"
    $compose_cmd ps
    echo
    
    if $compose_cmd ps | grep -q "claude-dev.*Up"; then
        log_success "Environment is running for project: $project_name"
        log_info "Container details:"
        docker exec -u 1000 "claude-dev-${project_name}" uname -a 2>/dev/null || true
        docker exec -u 1000 "claude-dev-${project_name}" claude --version 2>/dev/null || log_warning "Claude Code not responding"
    else
        log_warning "Environment is not running for project: $project_name"
        log_info "Use '$0 start' to start the environment"
    fi
}

# Build container
build_env() {
    local compose_cmd=$(get_compose_cmd)
    local project_name=$(get_project_name)
    
    log_info "Building shared container image..."
    $compose_cmd build --no-cache
    #$compose_cmd build 
    
    # ビルド成功後にハッシュを保存
    if [ -f Dockerfile ]; then
        sha256sum Dockerfile | awk '{print $1}' > ".dockerfile.sha256"
    fi
    
    log_success "Shared container image built!"
    log_info "Use '$0 start' to start the new container"
}

# Clean up
clean_env() {
    local compose_cmd=$(get_compose_cmd)
    
    log_warning "This will remove containers and images"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up..."
        $compose_cmd down --rmi all --volumes --remove-orphans
        log_success "Cleanup completed!"
    else
        log_info "Cleanup cancelled"
    fi
}

# Run tests
run_tests() {
    log_info "Running configuration tests..."
    
    if [ -f "./scripts/test-local.sh" ]; then
        ./scripts/test-local.sh
    elif [ -f "./test-local.sh" ]; then
        ./test-local.sh
    else
        log_error "Test script not found"
        exit 1
    fi
}

# Check environment
check_env() {
    log_header "=== Environment Check ==="
    echo
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        log_success "Docker: $(docker --version)"
        
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon: accessible"
        else
            log_warning "Docker daemon: not accessible (permission issue?)"
        fi
    else
        log_error "Docker: not installed"
    fi
    
    # Check Docker Compose
    if command -v docker-compose >/dev/null 2>&1; then
        log_success "Docker Compose: $(docker-compose --version)"
    elif docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose: $(docker compose version)"
    else
        log_error "Docker Compose: not installed"
    fi
    
    # Check .env file
    if [ -f .env ]; then
        if grep -q "ANTHROPIC_API_KEY=" .env && ! grep -q "your_api_key_here" .env; then
            log_success ".env: configured"
        else
            log_warning ".env: API key not configured"
        fi
    else
        log_warning ".env: not found"
    fi
    
    # Check configuration files
    local config_files=("Dockerfile" "docker-compose.yml" "claude-config/settings.json")
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "$file: exists"
        else
            log_error "$file: missing"
        fi
    done
    
    echo
    if command -v docker >/dev/null 2>&1 && (command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1); then
        log_success "Environment ready!"
    else
        log_warning "Environment needs setup. Run: $0 setup"
    fi
}

# Main function
main() {
    case "${1:-help}" in
        setup)
            setup_env
            ;;
        start)
            start_env
            ;;
        stop)
            stop_env
            ;;
        restart)
            restart_env
            ;;
        shell)
            enter_shell
            ;;
        claude)
            start_claude
            ;;
        gemini)
            start_gemini
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        build)
            build_env
            ;;
        clean)
            clean_env
            ;;
        test)
            run_tests
            ;;
        env)
            check_env
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
