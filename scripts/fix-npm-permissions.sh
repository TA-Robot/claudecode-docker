#!/bin/bash
# Script to fix npm permissions inside Docker container

echo "=== Fixing npm permissions ==="

# 1. Clean up existing npm cache
echo "1. Cleaning up npm cache..."
rm -rf /tmp/npm-cache 2>/dev/null || true
rm -rf ~/.npm 2>/dev/null || true
rm -rf ~/.cache/npm 2>/dev/null || true

# 2. Create new cache directory
echo "2. Creating new cache directory..."
mkdir -p /tmp/npm-cache
chmod -R 777 /tmp/npm-cache

# 3. Configure npm
echo "3. Configuring npm..."
npm config set cache /tmp/npm-cache
npm config set prefix /home/developer/.npm-global

# 4. Create .npmrc file
echo "4. Creating .npmrc file..."
cat > ~/.npmrc << EOF
cache=/tmp/npm-cache
prefix=/home/developer/.npm-global
fund=false
audit=false
EOF

# 5. Fix project directory permissions
echo "5. Fixing project directory permissions..."
if [[ -d /workspace/projects ]]; then
    # Find and fix root-owned files
    find /workspace/projects -user 0 -print0 2>/dev/null | while IFS= read -r -d '' file; do
        echo "Fixing: $file"
        # Since we can't use chown without sudo, we'll copy and replace
        if [[ -f "$file" ]]; then
            cp "$file" "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file" 2>/dev/null || true
        fi
    done
fi

# 6. Install npm packages with verbose output
echo "6. Installing npm packages..."
cd /workspace/projects
npm install --verbose --no-audit --no-fund --cache=/tmp/npm-cache

# 7. Fix node_modules permissions
echo "7. Fixing node_modules permissions..."
if [[ -d node_modules/.bin ]]; then
    find node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true
fi

echo "=== Permission fix completed ==="
echo "You can now run: npm test"