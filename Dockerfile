FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude

# Set working directory
WORKDIR /workspace

# Create directory for projects
RUN mkdir -p /workspace/projects

# Copy default configuration
COPY claude-config/ /root/.config/claude/

# Keep container running
CMD ["tail", "-f", "/dev/null"]