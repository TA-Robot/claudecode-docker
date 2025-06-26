#!/bin/bash

# Quick Validation Script
# Performs basic checks without deep validation or Docker.

set -e

# --- Test Helper Functions ---

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Counters for test results
PASS_COUNT=0
FAIL_COUNT=0

# Function to print a test result
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

# --- Test Execution ---

echo "=== AI Code Environment: Quick Validation Test ==="

# 1. Check for essential files and directories
echo "
[1. Checking for essential files...]"
files_to_check=(
    "Dockerfile"
    "docker-compose.yml"
    ".env.example"
    "dev.sh"
    "README.md"
    "CLAUDE.md"
    "GEMINI.md"
    "claude-config/settings.json"
    "projects/CLAUDE.md"
    "projects/GEMINI.md"
)
for f in "${files_to_check[@]}"; do
    test -f "$f"
    print_result "File exists: $f" $?
done

# 2. Quick check of Dockerfile content
echo "
[2. Performing quick Dockerfile checks...]"
grep -q "FROM node:20" Dockerfile
print_result "Dockerfile: Uses node:20 base image" $?
grep -q "@anthropic-ai/claude-code" Dockerfile
print_result "Dockerfile: Installs @anthropic-ai/claude-code" $?
grep -q "@google/gemini-cli" Dockerfile
print_result "Dockerfile: Installs @google/gemini-cli" $?

# 3. Quick check of docker-compose.yml content
echo "
[3. Performing quick docker-compose.yml checks...]"
grep -q "claude-dev:" docker-compose.yml
print_result "docker-compose.yml: Defines claude-dev service" $?
grep -q "./projects:/workspace/projects" docker-compose.yml
print_result "docker-compose.yml: Mounts ./projects directory" $?

# 4. Quick check of .env.example content
echo "
[4. Performing quick .env.example checks...]"
grep -q "ANTHROPIC_API_KEY=" .env.example
print_result ".env.example: Contains ANTHROPIC_API_KEY" $?
grep -q "GOOGLE_CLOUD_PROJECT=" .env.example
print_result ".env.example: Contains GOOGLE_CLOUD_PROJECT" $?

# --- Test Summary ---
echo "
--- Test Summary ---"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All $PASS_COUNT quick checks passed!${NC}"
    echo "Basic file structure and content seem correct."
    echo "Next step: Run './scripts/test-local.sh' for more detailed configuration checks."
    exit 0
else
    echo -e "${RED}Quick checks failed: $FAIL_COUNT failed, $PASS_COUNT passed.${NC}"
    echo "Please review the errors above."
    exit 1
fi
