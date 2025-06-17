#!/bin/bash

# Quick validation script (without Docker build/run)
echo "=== Quick Validation Test ==="
echo

# Check if required files exist
echo "1. File structure validation..."
files=(
    "Dockerfile:Docker configuration"
    "docker-compose.yml:Docker Compose configuration"
    ".env.example:Environment template"
    "claude-config/settings.json:Claude Code settings"
    "projects/CLAUDE.md:Project template"
    "README.md:Documentation"
    ".gitignore:Git ignore rules"
)

all_good=true
for item in "${files[@]}"; do
    file="${item%%:*}"
    desc="${item##*:}"
    if [[ -f "$file" ]]; then
        echo "✓ $file ($desc)"
    else
        echo "✗ $file missing ($desc)"
        all_good=false
    fi
done
echo

# Validate JSON syntax
echo "2. JSON syntax validation..."
if command -v python3 &> /dev/null; then
    if python3 -m json.tool claude-config/settings.json > /dev/null 2>&1; then
        echo "✓ settings.json has valid JSON syntax"
    else
        echo "✗ settings.json has invalid JSON syntax"
        all_good=false
    fi
else
    echo "⚠ Python3 not available, skipping JSON validation"
fi
echo

# Check Dockerfile syntax
echo "3. Dockerfile validation..."
if grep -q "FROM node:" Dockerfile && grep -q "RUN npm install -g @anthropic-ai/claude-code" Dockerfile; then
    echo "✓ Dockerfile contains expected Claude Code installation"
else
    echo "✗ Dockerfile missing Claude Code installation"
    all_good=false
fi
echo

# Check docker-compose.yml
echo "4. Docker Compose validation..."
if grep -q "volumes:" docker-compose.yml && grep -q "./projects:/workspace/projects" docker-compose.yml; then
    echo "✓ docker-compose.yml has volume mount configuration"
else
    echo "✗ docker-compose.yml missing volume configuration"
    all_good=false
fi
echo

# Check settings.json content
echo "5. Settings validation..."
if grep -q '"auto_approve"' claude-config/settings.json && grep -q '"enabled": true' claude-config/settings.json; then
    echo "✓ Auto-approve settings configured"
else
    echo "✗ Auto-approve settings not found"
    all_good=false
fi

if grep -q '"npm\*"' claude-config/settings.json && grep -q '"git\*"' claude-config/settings.json; then
    echo "✓ Common commands in auto-approve list"
else
    echo "✗ Common commands not in auto-approve list"
    all_good=false
fi
echo

# Summary
echo "=== Summary ==="
if $all_good; then
    echo "✓ All validations passed!"
    echo "Files are ready for Docker build and test."
    echo
    echo "Next steps:"
    echo "1. Run './test.sh' for full Docker test (requires Docker)"
    echo "2. Or manually: ./dev.sh build && ./dev.sh start"
else
    echo "✗ Some validations failed!"
    echo "Please fix the issues above before proceeding."
fi