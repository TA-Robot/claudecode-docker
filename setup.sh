#!/bin/bash

# Claude Code Docker Environment - Main Setup Script
# This is a convenience wrapper for the actual setup script

echo "Claude Code Docker Environment Setup"
echo "Redirecting to scripts/setup.sh..."
echo

# Check if scripts directory exists
if [ ! -d "scripts" ]; then
    echo "Error: scripts directory not found"
    exit 1
fi

# Run the actual setup script
exec ./scripts/setup.sh "$@"