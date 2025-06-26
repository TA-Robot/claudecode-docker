#!/bin/bash

# Local Configuration & Setup Test Script
# Validates the project's configuration files without requiring Docker.

# set -e

# --- Test Helper Functions ---

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters for test results
PASS_COUNT=0
FAIL_COUNT=0

# Function to print a test result
# Usage: print_result "Test description" $?
print_result() {
    local description="$1"
    local exit_code=$2
    if [ $exit_code -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((PASS_COUNT++))
    else
        echo -e "  ${RED}✗${NC} $description"
        ((FAIL_COUNT++))
    fi
}

# Function to check for the existence of a file
# Usage: check_file_exists "path/to/file"
check_file_exists() {
    local file_path="$1"
    test -f "$file_path"
    print_result "File exists: $file_path" $?
}

# Function to check if a file contains a specific pattern
# Usage: check_file_contains "path/to/file" "pattern"
check_file_contains() {
    local file_path="$1"
    local pattern="$2"
    grep -q "$pattern" "$file_path"
    print_result "File '$file_path' contains pattern: '$pattern'" $?
}

# --- Test Execution ---

echo "=== AI Code Environment: Local Configuration Test ==="

# 1. Core File Existence
echo "
[1. Checking for core project files...]"
check_file_exists "Dockerfile"
check_file_exists "docker-compose.yml"
check_file_exists ".env.example"
check_file_exists "dev.sh"
check_file_exists "README.md"

# 2. Dockerfile Validation
echo "
[2. Validating Dockerfile...]"
check_file_contains "Dockerfile" "FROM node:20"
check_file_contains "Dockerfile" "npm install -g @anthropic-ai/claude-code @google/gemini-cli"
check_file_contains "Dockerfile" "apt-get install -y google-cloud-cli"
check_file_contains "Dockerfile" "WORKDIR /workspace"

# 3. Docker Compose Validation
echo "
[3. Validating docker-compose.yml...]"
check_file_contains "docker-compose.yml" "claude-dev:"
check_file_contains "docker-compose.yml" "./projects:/workspace/projects"
check_file_contains "docker-compose.yml" "ANTHROPIC_API_KEY="
check_file_contains "docker-compose.yml" "GOOGLE_CLOUD_PROJECT=" "~/.config/gcloud:/home/developer/.config/gcloud:ro"

# 4. AI Context & Template Files
echo "
[4. Validating AI context and template files...]"
check_file_exists "CLAUDE.md"
check_file_exists "GEMINI.md"
check_file_exists "projects/CLAUDE.md"
check_file_exists "projects/GEMINI.md"
check_file_contains "projects/GEMINI.md" "Test-Driven Development (TDD) (MANDATORY)"

# 5. Environment Template Validation
echo "
[5. Validating .env.example...]"
check_file_contains ".env.example" "ANTHROPIC_API_KEY=your_api_key_here"
check_file_contains ".env.example" "GOOGLE_CLOUD_PROJECT=your_gcp_project_id_here"

# 6. Claude Code Specific Configuration
echo "
[6. Validating Claude Code configuration (settings.json)...]"
check_file_exists "claude-config/settings.json"
if command -v jq &> /dev/null; then
    jq -e '.tool_permissions.bash == "allow"' claude-config/settings.json > /dev/null
    print_result "jq: .tool_permissions.bash is 'allow'" $?
    jq -e '.auto_approve.enabled == true' claude-config/settings.json > /dev/null
    print_result "jq: .auto_approve.enabled is true" $?
    jq -e '(.security.blocked_commands | length) > 0' claude-config/settings.json > /dev/null
    print_result "jq: .security.blocked_commands is not empty" $?
else
    echo -e "  ${YELLOW}⚠ jq not found, skipping detailed JSON validation.${NC}"
fi

# --- Test Summary ---
echo "
--- Test Summary ---"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All $PASS_COUNT tests passed!${NC}"
    echo "Configuration appears to be correct."
    echo "Next step: Run './scripts/test.sh' for a full end-to-end test with Docker."
    exit 0
else
    echo -e "${RED}Tests failed: $FAIL_COUNT failed, $PASS_COUNT passed.${NC}"
    echo "Please review the errors above."
    exit 1
fi
