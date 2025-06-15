#!/bin/bash
# Container initialization script - runs in background on startup

echo "[init-container] Starting background initialization..."

# Wait a bit for the container to stabilize
sleep 2

# Function to initialize a project
init_project() {
    local project_dir="$1"
    local project_name=$(basename "$project_dir")
    
    echo "[init-container] Initializing project: $project_name"
    
    cd "$project_dir"
    
    # Clean up old npm cache and modules
    rm -rf node_modules package-lock.json .npm-cache 2>/dev/null
    
    # Install dependencies
    echo "[init-container] Installing dependencies for $project_name..."
    npm install --no-audit --no-fund --cache=/tmp/npm-cache --loglevel=error
    
    # Fix permissions
    if [[ -d node_modules/.bin ]]; then
        echo "[init-container] Fixing permissions for $project_name..."
        find node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true
    fi
    
    echo "[init-container] Project $project_name initialized successfully"
}

# Initialize all projects with package.json
if [[ -d /workspace/projects ]]; then
    for project in /workspace/projects/*; do
        if [[ -f "$project/package.json" ]]; then
            init_project "$project"
        fi
    done
fi

echo "[init-container] Background initialization completed"