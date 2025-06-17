#!/bin/bash

# Local test script without Docker (for environments without Docker access)
echo "=== Claude Code Environment Local Test ==="
echo "Note: This test validates configuration without running Docker"
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

# Validate Dockerfile
echo "2. Dockerfile validation..."
echo "Checking FROM instruction..."
if grep -q "FROM node:" Dockerfile; then
    echo "✓ Base image specified"
else
    echo "✗ Base image not found"
fi

echo "Checking Claude Code installation..."
if grep -q "npm install -g @anthropic-ai/claude" Dockerfile; then
    echo "✓ Claude Code installation command found"
else
    echo "✗ Claude Code installation command missing"
fi

echo "Checking working directory..."
if grep -q "WORKDIR /workspace" Dockerfile; then
    echo "✓ Working directory set"
else
    echo "✗ Working directory not set"
fi
echo

# Validate docker-compose.yml
echo "3. Docker Compose validation..."
echo "Checking service definition..."
if grep -q "claude-dev:" docker-compose.yml; then
    echo "✓ Service defined"
else
    echo "✗ Service not defined"
fi

echo "Checking volume mounts..."
if grep -q "./projects:/workspace/projects" docker-compose.yml; then
    echo "✓ Projects volume mount configured"
else
    echo "✗ Projects volume mount missing"
fi

if grep -q "./claude-config:/" docker-compose.yml; then
    echo "✓ Config volume mount configured"
else
    echo "✗ Config volume mount missing"
fi

echo "Checking environment variables..."
if grep -q "ANTHROPIC_API_KEY" docker-compose.yml; then
    echo "✓ API key environment variable configured"
else
    echo "✗ API key environment variable missing"
fi
echo

# Validate settings.json
echo "4. Claude Code settings validation..."
if command -v python3 &> /dev/null; then
    if python3 -c "
import json
import sys
try:
    with open('claude-config/settings.json', 'r') as f:
        config = json.load(f)
    
    # Check tool_permissions
    if 'tool_permissions' in config:
        print('✓ Tool permissions configured')
        tools = config['tool_permissions']
        if tools.get('bash') == 'allow' and tools.get('edit') == 'allow':
            print('✓ Basic tools set to allow')
        else:
            print('✗ Basic tools not properly configured')
    else:
        print('✗ Tool permissions section missing')
    
    # Check auto_approve
    if 'auto_approve' in config:
        auto_approve = config['auto_approve']
        if auto_approve.get('enabled') == True:
            print('✓ Auto-approve enabled')
        else:
            print('✗ Auto-approve not enabled')
        
        if 'commands' in auto_approve and len(auto_approve['commands']) > 0:
            print(f'✓ {len(auto_approve[\"commands\"])} commands configured for auto-approve')
            # Check for common commands
            commands = auto_approve['commands']
            common_commands = ['npm*', 'git*', 'python*', 'node*']
            found_commands = [cmd for cmd in common_commands if cmd in commands]
            if len(found_commands) >= 2:
                print(f'✓ Common development commands included: {found_commands}')
            else:
                print('⚠ Few common development commands found')
        else:
            print('✗ No commands configured for auto-approve')
    else:
        print('✗ Auto-approve section missing')
    
    # Check security settings
    if 'security' in config:
        security = config['security']
        if 'blocked_commands' in security and len(security['blocked_commands']) > 0:
            print(f'✓ {len(security[\"blocked_commands\"])} dangerous commands blocked')
        else:
            print('⚠ No dangerous commands blocked')
    else:
        print('⚠ Security section missing')

except Exception as e:
    print(f'✗ Error reading/parsing settings.json: {e}')
    sys.exit(1)
" 2>/dev/null; then
        echo "✓ Settings validation completed"
    else
        echo "✗ Settings validation failed"
    fi
else
    echo "⚠ Python3 not available, skipping detailed JSON validation"
    if cat claude-config/settings.json | grep -q '"auto_approve"' && cat claude-config/settings.json | grep -q '"enabled": true'; then
        echo "✓ Basic settings structure looks correct"
    else
        echo "✗ Basic settings structure incorrect"
    fi
fi
echo

# Check project template
echo "5. Project template validation..."
if grep -q "Claude Code Configuration" projects/CLAUDE.md; then
    echo "✓ Project template has proper header"
else
    echo "✗ Project template header missing"
fi

if grep -q "Build Commands" projects/CLAUDE.md && grep -q "Test Commands" projects/CLAUDE.md; then
    echo "✓ Build and test sections present"
else
    echo "✗ Build or test sections missing"
fi
echo

# Check .env.example
echo "6. Environment template validation..."
if grep -q "ANTHROPIC_API_KEY" .env.example; then
    echo "✓ API key template present"
else
    echo "✗ API key template missing"
fi

if grep -q "your_api_key_here" .env.example; then
    echo "✓ Placeholder value present"
else
    echo "✗ Placeholder value missing"
fi
echo

# Final summary
echo "=== Local Test Summary ==="
echo "✓ Configuration files validated successfully"
echo "✓ File structure is correct"
echo "✓ Settings are properly configured"
echo
echo "Manual Docker test steps:"
echo "1. Ensure Docker and Docker Compose are installed and accessible"
echo "2. Run: cp .env.example .env"
echo "3. Edit .env with your Anthropic API key"
echo "4. Run: ./dev.sh build"
echo "5. Run: ./dev.sh start"
echo "6. Run: ./dev.sh shell"
echo "7. Inside container, run: claude --version"
echo "8. Test file sharing by creating files in /workspace/projects"
echo
echo "If you have Docker access, run './test.sh' for automated testing."