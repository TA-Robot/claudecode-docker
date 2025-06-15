#!/bin/bash
# Script to fix jest and other npm executable permissions in Docker container

echo "=== Fixing Jest and npm executable permissions ==="

# Function to fix permissions in a directory
fix_directory_permissions() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo "Fixing permissions in: $dir"
        find "$dir" -type f -name "jest" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "mocha" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "ts-node" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "tsc" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "eslint" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "prettier" -exec chmod +x {} \; 2>/dev/null || true
        find "$dir" -type f -name "nodemon" -exec chmod +x {} \; 2>/dev/null || true
        # Fix all files in .bin directories
        if [[ -d "$dir/.bin" ]]; then
            chmod +x "$dir/.bin/"* 2>/dev/null || true
        fi
    fi
}

# Fix global npm modules
echo "1. Fixing global npm modules..."
fix_directory_permissions "/usr/local/lib/node_modules"
fix_directory_permissions "/home/developer/.npm-global/lib/node_modules"

# Fix project-specific node_modules
echo "2. Fixing project node_modules..."
if [[ -d /workspace/projects ]]; then
    for project in /workspace/projects/*; do
        if [[ -d "$project/node_modules" ]]; then
            echo "   - Fixing: $(basename $project)"
            fix_directory_permissions "$project/node_modules"
            # Also fix the .bin directory specifically
            if [[ -d "$project/node_modules/.bin" ]]; then
                chmod +x "$project/node_modules/.bin/"* 2>/dev/null || true
            fi
        fi
    done
fi

# Fix current directory if it has node_modules
echo "3. Fixing current directory node_modules..."
if [[ -d ./node_modules ]]; then
    fix_directory_permissions "./node_modules"
fi

# Create a wrapper for jest if it doesn't exist
echo "4. Creating jest wrapper if needed..."
if ! command -v jest &> /dev/null; then
    cat > /home/developer/.npm-global/bin/jest << 'EOF'
#!/bin/sh
if [ -x "./node_modules/.bin/jest" ]; then
    exec ./node_modules/.bin/jest "$@"
elif [ -x "/usr/local/lib/node_modules/jest/bin/jest.js" ]; then
    exec node /usr/local/lib/node_modules/jest/bin/jest.js "$@"
else
    echo "Error: jest not found"
    exit 1
fi
EOF
    chmod +x /home/developer/.npm-global/bin/jest
fi

echo "=== Permission fix completed ==="
echo ""
echo "If you still get permission errors, try:"
echo "  1. Run: chmod +x ./node_modules/.bin/jest"
echo "  2. Run: npx jest (instead of npm test)"
echo "  3. Run: node ./node_modules/.bin/jest"