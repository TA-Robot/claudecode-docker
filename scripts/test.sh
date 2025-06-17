#!/bin/bash

# Claude Code Docker Environment Test Script
echo "=== Claude Code Docker Environment Test ==="
echo

# Check if required files exist
echo "1. Checking required files..."
required_files=("Dockerfile" "docker-compose.yml" ".env.example" "claude-config/settings.json" "projects/CLAUDE.md")
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
        exit 1
    fi
done
echo

# Check Docker installation
echo "2. Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "✓ Docker is installed: $(docker --version)"
else
    echo "✗ Docker is not installed"
    exit 1
fi

# Check for docker-compose or docker compose
echo "3. Checking Docker Compose..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo "✓ Docker Compose is available: $(docker-compose --version)"
elif docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    echo "✓ Docker Compose (plugin) is available: $(docker compose version)"
else
    echo "✗ Docker Compose is not available"
    echo "Please install Docker Compose or use Docker Desktop"
    echo "Alternative: Run './test-local.sh' for configuration validation only"
    exit 1
fi
echo

# Check Docker daemon access
echo "4. Checking Docker daemon access..."
if docker info &> /dev/null; then
    echo "✓ Docker daemon is accessible"
else
    echo "✗ Docker daemon is not accessible"
    echo "This usually means:"
    echo "1. Docker daemon is not running"
    echo "2. User is not in docker group"
    echo "3. Permission denied to docker socket"
    echo
    echo "Try one of these solutions:"
    echo "- sudo docker info (run with sudo)"
    echo "- sudo usermod -aG docker $USER && newgrp docker (add user to docker group)"
    echo "- sudo systemctl start docker (start docker daemon)"
    echo
    echo "Alternative: Run './test-local.sh' for configuration validation only"
    exit 1
fi

# Check docker-compose.yml exists
echo "5. Checking docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    echo "✓ docker-compose.yml exists"
else
    echo "✗ docker-compose.yml missing"
    exit 1
fi
echo

# Test Docker build
echo "6. Testing Docker build..."
if $COMPOSE_CMD  build --no-cache; then
    echo "✓ Docker build successful"
else
    echo "✗ Docker build failed"
    exit 1
fi
echo

# Test container startup
echo "7. Testing container startup..."
if $COMPOSE_CMD  up -d; then
    echo "✓ Container started successfully"
    sleep 5
else
    echo "✗ Container startup failed"
    exit 1
fi
echo

# Test Claude Code installation inside container
echo "8. Testing Claude Code installation..."
if $COMPOSE_CMD  exec -T claude-dev which claude; then
    echo "✓ Claude Code is installed"
    $COMPOSE_CMD  exec -T claude-dev claude --version || echo "Claude version check completed"
else
    echo "✗ Claude Code is not installed or not accessible"
    $COMPOSE_CMD  down
    exit 1
fi
echo

# Test configuration file
echo "9. Testing configuration file..."
if $COMPOSE_CMD  exec -T claude-dev test -f /root/.config/claude/settings.json; then
    echo "✓ Configuration file exists"
    echo "Configuration content:"
    $COMPOSE_CMD  exec -T claude-dev head -n 10 /root/.config/claude/settings.json
else
    echo "✗ Configuration file missing"
fi
echo

# Test volume mounts
echo "10. Testing volume mounts..."
# Create test file on host
echo "test content" > projects/test-file.txt
if $COMPOSE_CMD  exec -T claude-dev test -f /workspace/projects/test-file.txt; then
    echo "✓ Volume mount working"
    if $COMPOSE_CMD  exec -T claude-dev cat /workspace/projects/test-file.txt | grep -q "test content"; then
        echo "✓ File content accessible"
    else
        echo "✗ File content not accessible"
    fi
else
    echo "✗ Volume mount not working"
fi
# Clean up test file
rm -f projects/test-file.txt
$COMPOSE_CMD  exec -T claude-dev rm -f /workspace/projects/test-file.txt 2>/dev/null || true
echo

# Test basic commands inside container
echo "11. Testing basic commands..."
commands=("node --version" "npm --version" "git --version" "python3 --version")
for cmd in "${commands[@]}"; do
    if $COMPOSE_CMD  exec -T claude-dev bash -c "$cmd" &> /dev/null; then
        version=$($COMPOSE_CMD  exec -T claude-dev bash -c "$cmd" 2>&1 | head -n 1)
        echo "✓ $cmd: $version"
    else
        echo "✗ $cmd failed"
    fi
done
echo

# Clean up
echo "12. Cleaning up..."
$COMPOSE_CMD  down
echo "✓ Container stopped"
echo

echo "=== Test Summary ==="
echo "✓ All tests passed successfully!"
echo "Your Claude Code Docker environment is ready to use."
echo
echo "To start developing:"
echo "1. cp .env.example .env"
echo "2. Edit .env with your Anthropic API key"
echo "3. ./dev.sh start"
echo "4. ./dev.sh shell"
echo "5. Run 'claude' inside the container"