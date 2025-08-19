FROM node:20

# Optional: toggle Codex CLI installation at build-time
ARG INSTALL_CODEX=true

# Set timezone and locale
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# Install development tools, locale support, and build essentials
RUN apt-get update && apt-get install -y \
    git \
    zsh \
    fzf \
    jq \
    unzip \
    curl \
    wget \
    vim \
    nano \
    bash-completion \
    locales \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    postgresql-client \
    chromium \
    netcat-openbsd \
    nginx \
    redis-tools \
    sudo     && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/google-cloud.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &&     curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/google-cloud.gpg add - &&     apt-get update && apt-get install -y google-cloud-cli

# Generate Japanese locale
RUN sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Docker (Docker-in-Docker support)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/* && \
    # Create docker group with common GIDs (try multiple common GIDs)
    (groupadd -g 999 docker 2>/dev/null || groupadd -g 998 docker 2>/dev/null || groupadd docker 2>/dev/null || true)

# Reuse existing node user (UID 1000) as developer
RUN existing_user=$(getent passwd 1000 | cut -d: -f1) && \
    if [ -n "$existing_user" ]; then \
        # Rename existing user to developer
        usermod -l developer -d /home/developer -m "$existing_user" && \
        groupmod -n developer $(id -gn developer) && \
        usermod -s /bin/zsh developer; \
    else \
        # Create new developer user if UID 1000 doesn't exist
        groupadd -g 1000 developer && \
        useradd -u 1000 -g 1000 -m -d /home/developer -s /bin/zsh developer; \
    fi && \
    # Add developer user to docker group (Docker group already exists from Docker installation)
    usermod -aG docker developer && \
    # Give docker command sudo access for permission fixes
    echo "developer ALL=(ALL) NOPASSWD: /usr/bin/docker" > /etc/sudoers.d/developer-docker && \
    chmod 0440 /etc/sudoers.d/developer-docker

# Install additional development languages and tools
RUN apt-get update && apt-get install -y \
    # Go language
    golang-go \
    # Java
    default-jdk \
    maven \
    # Additional tools
    tree \
    htop \
    rsync \
    zip \
    tmux \
    screen \
    # Playwright dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libatspi2.0-0 \
    libxdamage1 \
    libgbm1 \
    libgtk-3-0 \
    libxss1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (as root initially, will be configured for user later)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=\"/root/.cargo/bin:${PATH}\"

# Set npm global permissions and install CLIs
RUN chown -R 1000:1000 /usr/local/lib/node_modules || true && \
    chmod -R 755 /usr/local/lib/node_modules || true && \
    npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex || true && \
    # Install common global npm tools with proper permissions

    npm install -g \
        typescript \
        ts-node \
        nodemon \
        jest \
        mocha \
        eslint \
        prettier \
        webpack \
        webpack-cli \
        vite \
        create-react-app \
        @angular/cli \
        @vue/cli \
        yarn \
        pnpm \
        npm-check-updates \
        concurrently \
        cross-env \
        dotenv-cli \
        rimraf \
        && \
    # Fix permissions for all global npm binaries
    chmod -R +x /usr/local/lib/node_modules/.bin/* 2>/dev/null || true && \
    chmod -R +x /usr/local/bin/* 2>/dev/null || true

# Best-effort install of Codex CLI (optional; npm recommended, latest)
RUN if [ "$INSTALL_CODEX" = "true" ]; then \
      echo "Attempting to install Codex CLI via npm (latest)..." && \
      npm config set registry https://registry.npmjs.org/ && \
      (npm install -g @openai/codex-cli || true) && \
      (command -v codex >/dev/null 2>&1 || command -v codex-cli >/dev/null 2>&1 || echo "Codex CLI not found; continuing without it"); \
    else \
      echo "Skipping Codex CLI installation (INSTALL_CODEX=$INSTALL_CODEX)"; \
    fi

# Configure npm for custom user
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global
ENV NPM_CONFIG_CACHE=/tmp/npm-cache
ENV PATH=$PATH:/home/developer/.npm-global/bin:/home/developer/.local/bin

# Playwright environment variables
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# Set working directory and create project directories with proper permissions
WORKDIR /workspace
RUN mkdir -p /workspace/projects && \
    mkdir -p /workspace/logs && \
    mkdir -p /workspace/coverage && \
    mkdir -p /workspace/test-results && \
    chown -R 1000:1000 /workspace && \
    chmod -R 755 /workspace && \
    chmod -R 777 /workspace/logs && \
    chmod -R 777 /workspace/coverage && \
    chmod -R 777 /workspace/test-results

# Create directories with proper permissions
RUN mkdir -p /home/developer/.npm-global && \
    mkdir -p /home/developer/.claude && \
    mkdir -p /home/developer/.cache/claude && \
    mkdir -p /home/developer/.local/bin && \
    mkdir -p /home/developer/.cargo && \
    mkdir -p /home/developer/.rustup && \
    mkdir -p /home/developer/.config && \
    mkdir -p /home/developer/.cache/pip && \
    mkdir -p /home/developer/.cache/go-build && \
    mkdir -p /home/developer/.cache/maven && \
    mkdir -p /home/developer/go/bin && \
    mkdir -p /home/developer/go/src && \
    mkdir -p /home/developer/go/pkg && \
    mkdir -p /home/developer/.local/lib/python3.11/site-packages && \
    mkdir -p /tmp/developer && \
    mkdir -p /home/developer/.venv && \
    mkdir -p /home/developer/.pyenv && \
    mkdir -p /home/developer/.poetry && \
    mkdir -p /home/developer/.pipx && \
    mkdir -p /home/developer/.bundle && \
    mkdir -p /home/developer/.gem && \
    mkdir -p /home/developer/.gradle && \
    mkdir -p /home/developer/.m2 && \
    mkdir -p /home/developer/.docker && \
    mkdir -p /home/developer/.kube && \
    mkdir -p /home/developer/.ssh && \
    mkdir -p /home/developer/.gnupg && \
    mkdir -p /home/developer/.git && \
    mkdir -p /home/developer/.gitconfig.d && \
    chown -R 1000:1000 /home/developer && \
    chown -R 1000:1000 /workspace && \
    chown 1000:1000 /tmp/developer && \
    chmod 755 /tmp/developer && \
    # Set specific npm permissions
    chown -R 1000:1000 /home/developer/.npm-global && \
    chmod -R 755 /home/developer/.npm-global && \
    # Set Python permissions
    chmod -R 755 /home/developer/.local && \
    chmod -R 755 /home/developer/.cache/pip && \
    chmod -R 755 /home/developer/.venv && \
    chmod -R 755 /home/developer/.pyenv && \
    chmod -R 755 /home/developer/.poetry && \
    chmod -R 755 /home/developer/.pipx && \
    # Set Go/Rust permissions
    chmod -R 755 /home/developer/go && \
    chmod -R 755 /home/developer/.cargo && \
    chmod -R 755 /home/developer/.rustup && \
    # Set Java/Maven/Gradle permissions
    chmod -R 755 /home/developer/.gradle && \
    chmod -R 755 /home/developer/.m2 && \
    chmod -R 755 /home/developer/.cache/maven && \
    # Set Docker/Kubernetes permissions
    chmod -R 755 /home/developer/.docker && \
    chmod -R 755 /home/developer/.kube && \
    # Set SSH/GPG permissions
    chmod 700 /home/developer/.ssh && \
    chmod 700 /home/developer/.gnupg && \
    # Set Git permissions
    chmod -R 755 /home/developer/.git && \
    chmod -R 755 /home/developer/.gitconfig.d && \
    # Set development tool permissions
    chmod +x /usr/bin/git /usr/bin/curl /usr/bin/wget /usr/bin/vim /usr/bin/nano && \
    chmod +x /usr/bin/python3 /usr/bin/pip3 && \
    chmod +x /usr/bin/go /usr/bin/javac /usr/bin/java /usr/bin/mvn && \
    chmod +x /usr/bin/docker /usr/bin/docker-compose && \
    # Set npm and node_modules permissions
    chmod +x /usr/local/bin/npm /usr/local/bin/node /usr/local/bin/npx && \
    chmod -R +x /usr/local/lib/node_modules/.bin/* 2>/dev/null || true && \
    # Set detailed filesystem permissions
    chmod 755 /workspace && \
    chmod 755 /workspace/projects && \
    # Allow access to common system directories for development
    chmod 755 /var/log || true && \
    mkdir -p /var/log/developer && \
    chown 1000:1000 /var/log/developer && \
    chmod 755 /var/log/developer && \
    # Set permissions for common development directories
    chmod 755 /home/developer/.config && \
    chmod 755 /home/developer/.cache && \
    chmod 755 /home/developer/.local

# Copy default configuration
COPY claude-config/ /home/developer/.claude/
RUN chown -R 1000:1000 /home/developer/.claude/ && \
    chmod -R 755 /home/developer/.claude/

# Copy npmrc template
COPY .npmrc.template /home/developer/.npmrc
RUN chown 1000:1000 /home/developer/.npmrc

# Copy helper scripts
RUN mkdir -p /home/developer/bin
COPY scripts/fix-npm-permissions.sh /home/developer/bin/
COPY scripts/init-container.sh /home/developer/bin/
COPY scripts/fix-jest-permissions.sh /home/developer/bin/
RUN chmod +x /home/developer/bin/fix-npm-permissions.sh && \
    chmod +x /home/developer/bin/init-container.sh && \
    chmod +x /home/developer/bin/fix-jest-permissions.sh && \
    chown -R 1000:1000 /home/developer/bin

# Create npm cache directories with proper ownership before switching user
RUN mkdir -p /home/developer/.cache/npm/_cacache/tmp && \
    mkdir -p /home/developer/.cache/npm/_logs && \
    mkdir -p /home/developer/.cache/npm/_npx && \
    mkdir -p /home/developer/.npm-global/lib/node_modules && \
    mkdir -p /home/developer/.npm-global/bin && \
    mkdir -p /tmp/npm-cache && \
    chown -R 1000:1000 /home/developer/.npm-global && \
    chown -R 1000:1000 /home/developer/.cache && \
    chown -R 1000:1000 /tmp/npm-cache && \
    chmod -R 755 /home/developer/.npm-global && \
    chmod -R 755 /home/developer/.cache && \
    chmod -R 777 /tmp/npm-cache && \
    # Remove any existing .npm directory to avoid conflicts
    rm -rf /home/developer/.npm

# Switch to user with UID 1000
USER 1000

# Set environment variables for the user
ENV HOME=/home/developer
ENV USER=developer
ENV PATH=/home/developer/.local/bin:/home/developer/bin:/home/developer/.cargo/bin:$PATH:/home/developer/.npm-global/bin

# Change to home directory
WORKDIR /home/developer

# Install and configure Oh My Zsh with timeout and retry
RUN for i in 1 2 3; do \
        echo "Attempt $i to install Oh My Zsh..." && \
        echo "Current directory: $(pwd)" && \
        echo "User: $(whoami)" && \
        echo "HOME: $HOME" && \
        curl -fsSL --connect-timeout 30 --max-time 120 https://cdn.jsdelivr.net/gh/ohmyzsh/ohmyzsh@master/tools/install.sh -o /tmp/install_omz.sh && \
        sh /tmp/install_omz.sh --unattended && \
        rm -f /tmp/install_omz.sh && \
        break || \
        (echo "Attempt $i failed, retrying..." && sleep 5); \
    done && \
    # Create .zshrc if it doesn't exist (in case oh-my-zsh installation failed)
    touch /home/developer/.zshrc && \
    # Add null_glob option at the beginning of .zshrc to prevent wildcard errors
    echo '# Prevent "no matches found" errors' > /tmp/zshrc_header && \
    echo 'setopt null_glob' >> /tmp/zshrc_header && \
    echo 'setopt no_nomatch' >> /tmp/zshrc_header && \
    echo '' >> /tmp/zshrc_header && \
    cat /home/developer/.zshrc >> /tmp/zshrc_header && \
    mv /tmp/zshrc_header /home/developer/.zshrc

# Install Rust for the user (since we switched to user 1000)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source $HOME/.cargo/env' >> /home/developer/.zshrc

# Configure environment paths and development tool permissions for the user
RUN echo '# Custom environment paths' >> /home/developer/.zshrc && \
    echo 'export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$PATH"' >> /home/developer/.zshrc && \
    echo 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"' >> /home/developer/.zshrc && \
    echo 'export NPM_CONFIG_CACHE="/tmp/npm-cache"' >> /home/developer/.zshrc && \
    echo 'export PATH="$PATH:$HOME/.npm-global/bin"' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Development tool configurations' >> /home/developer/.zshrc && \
    echo 'export GOPATH="$HOME/go"' >> /home/developer/.zshrc && \
    echo 'export PATH="$PATH:$GOPATH/bin"' >> /home/developer/.zshrc && \
    echo 'export CARGO_HOME="$HOME/.cargo"' >> /home/developer/.zshrc && \
    echo 'export RUSTUP_HOME="$HOME/.rustup"' >> /home/developer/.zshrc && \
    echo 'export JAVA_HOME="/usr/lib/jvm/default-java"' >> /home/developer/.zshrc && \
    echo 'export MAVEN_HOME="/usr/share/maven"' >> /home/developer/.zshrc && \
    echo 'export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"' >> /home/developer/.zshrc && \
    echo 'export PIP_USER=1' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Create necessary directories and fix node_modules permissions' >> /home/developer/.zshrc && \
    echo 'mkdir -p $HOME/go/bin $HOME/go/src $HOME/go/pkg 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '# Fix permissions after npm install' >> /home/developer/.zshrc && \
    echo 'fix_npm_permissions() {' >> /home/developer/.zshrc && \
    echo '  if [[ -d ./node_modules/.bin ]]; then' >> /home/developer/.zshrc && \
    echo '    find ./node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '}' >> /home/developer/.zshrc && \
    echo '# Run after npm install' >> /home/developer/.zshrc && \
    echo 'npm() {' >> /home/developer/.zshrc && \
    echo '  command npm "$@"' >> /home/developer/.zshrc && \
    echo '  if [[ "$1" == "install" ]] || [[ "$1" == "i" ]] || [[ "$1" == "ci" ]]; then' >> /home/developer/.zshrc && \
    echo '    fix_npm_permissions' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '}' >> /home/developer/.zshrc && \
    echo '# Use glob with null_glob option to avoid errors when no files match' >> /home/developer/.zshrc && \
    echo 'setopt null_glob' >> /home/developer/.zshrc && \
    echo 'for f in ./node_modules/.bin/*(N); do chmod +x "$f" 2>/dev/null || true; done' >> /home/developer/.zshrc && \
    echo 'for f in $HOME/.npm-global/lib/node_modules/.bin/*(N); do chmod +x "$f" 2>/dev/null || true; done' >> /home/developer/.zshrc && \
    echo 'unsetopt null_glob' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Auto-fix permissions when entering a directory' >> /home/developer/.zshrc && \
    echo 'chpwd() {' >> /home/developer/.zshrc && \
    echo '  # Fix npm/node permissions' >> /home/developer/.zshrc && \
    echo '  if [[ -d ./node_modules/.bin ]]; then' >> /home/developer/.zshrc && \
    echo '    chmod -R +x ./node_modules/.bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '  # Fix Python virtual environment permissions' >> /home/developer/.zshrc && \
    echo '  if [[ -d ./venv/bin ]] || [[ -d ./.venv/bin ]]; then' >> /home/developer/.zshrc && \
    echo '    chmod -R +x ./venv/bin/* ./.venv/bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '  # Fix local bin permissions' >> /home/developer/.zshrc && \
    echo '  if [[ -d ./bin ]]; then' >> /home/developer/.zshrc && \
    echo '    chmod -R +x ./bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '  # Fix package.json scripts permissions' >> /home/developer/.zshrc && \
    echo '  if [[ -f ./package.json ]] && [[ -d ./node_modules/.bin ]]; then' >> /home/developer/.zshrc && \
    echo '    find ./node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '  # Fix cargo target permissions' >> /home/developer/.zshrc && \
    echo '  if [[ -d ./target/debug ]] || [[ -d ./target/release ]]; then' >> /home/developer/.zshrc && \
    echo '    find ./target -type f -executable -exec chmod +x {} \; 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '}' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Helper function to fix all common permission issues' >> /home/developer/.zshrc && \
    echo 'fixperms() {' >> /home/developer/.zshrc && \
    echo '  echo "Fixing permissions..."' >> /home/developer/.zshrc && \
    echo '  # Run the comprehensive fix script if available' >> /home/developer/.zshrc && \
    echo '  if [[ -x /home/developer/bin/fix-jest-permissions.sh ]]; then' >> /home/developer/.zshrc && \
    echo '    /home/developer/bin/fix-jest-permissions.sh' >> /home/developer/.zshrc && \
    echo '    return' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo '  # Fix npm permissions' >> /home/developer/.zshrc && \
    echo '  [[ -d node_modules/.bin ]] && chmod -R +x node_modules/.bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  [[ -d ~/.npm-global/lib/node_modules/.bin ]] && chmod -R +x ~/.npm-global/lib/node_modules/.bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  # Fix Python permissions' >> /home/developer/.zshrc && \
    echo '  [[ -d venv/bin ]] && chmod -R +x venv/bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  [[ -d .venv/bin ]] && chmod -R +x .venv/bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  [[ -d ~/.local/bin ]] && chmod -R +x ~/.local/bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  # Fix Go permissions' >> /home/developer/.zshrc && \
    echo '  [[ -d ~/go/bin ]] && chmod -R +x ~/go/bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  # Fix Rust permissions' >> /home/developer/.zshrc && \
    echo '  [[ -d ~/.cargo/bin ]] && chmod -R +x ~/.cargo/bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  [[ -d target ]] && find target -type f -executable -exec chmod +x {} \; 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  # Fix local bin permissions' >> /home/developer/.zshrc && \
    echo '  [[ -d bin ]] && chmod -R +x bin/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  [[ -d scripts ]] && chmod -R +x scripts/* 2>/dev/null' >> /home/developer/.zshrc && \
    echo '  echo "Permissions fixed!"' >> /home/developer/.zshrc && \
    echo '}' >> /home/developer/.zshrc

# Configure zsh with useful settings
RUN echo '# Custom zsh configuration' >> /home/developer/.zshrc && \
    echo 'export PS1="%F{cyan}%n@%m%f:%F{yellow}%~%f$ "' >> /home/developer/.zshrc && \
    echo 'setopt PROMPT_SUBST' >> /home/developer/.zshrc && \
    echo 'export PROMPT_DIRTRIM=0' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# History settings' >> /home/developer/.zshrc && \
    echo 'HISTSIZE=10000' >> /home/developer/.zshrc && \
    echo 'SAVEHIST=10000' >> /home/developer/.zshrc && \
    echo 'setopt HIST_IGNORE_DUPS' >> /home/developer/.zshrc && \
    echo 'setopt HIST_IGNORE_ALL_DUPS' >> /home/developer/.zshrc && \
    echo 'setopt HIST_SAVE_NO_DUPS' >> /home/developer/.zshrc && \
    echo 'setopt HIST_FIND_NO_DUPS' >> /home/developer/.zshrc && \
    echo 'setopt SHARE_HISTORY' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Directory navigation' >> /home/developer/.zshrc && \
    echo 'setopt AUTO_CD' >> /home/developer/.zshrc && \
    echo 'setopt AUTO_PUSHD' >> /home/developer/.zshrc && \
    echo 'setopt PUSHD_IGNORE_DUPS' >> /home/developer/.zshrc && \
    echo 'setopt PUSHD_SILENT' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Completion settings' >> /home/developer/.zshrc && \
    echo 'setopt AUTO_MENU' >> /home/developer/.zshrc && \
    echo 'setopt COMPLETE_IN_WORD' >> /home/developer/.zshrc && \
    echo 'setopt ALWAYS_TO_END' >> /home/developer/.zshrc && \
    echo 'zstyle ":completion:*" menu select' >> /home/developer/.zshrc && \
    echo 'zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Useful aliases' >> /home/developer/.zshrc && \
    echo 'alias ll="ls -alF"' >> /home/developer/.zshrc && \
    echo 'alias la="ls -A"' >> /home/developer/.zshrc && \
    echo 'alias l="ls -CF"' >> /home/developer/.zshrc && \
    echo 'alias ..="cd .."' >> /home/developer/.zshrc && \
    echo 'alias ...="cd ../.."' >> /home/developer/.zshrc && \
    echo 'alias grep="grep --color=auto"' >> /home/developer/.zshrc && \
    echo 'alias fgrep="fgrep --color=auto"' >> /home/developer/.zshrc && \
    echo 'alias egrep="egrep --color=auto"' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Docker-in-Docker socket permissions fix' >> /home/developer/.zshrc && \
    echo 'if [[ -S /var/run/docker.sock ]]; then' >> /home/developer/.zshrc && \
    echo '  # Check Docker access on shell startup' >> /home/developer/.zshrc && \
    echo '  if ! docker version >/dev/null 2>&1; then' >> /home/developer/.zshrc && \
    echo '    echo "⚠️  Docker socket is not accessible. You may need to:"' >> /home/developer/.zshrc && \
    echo '    echo "   1. Ensure Docker socket is mounted with correct permissions"' >> /home/developer/.zshrc && \
    echo '    echo "   2. Check if user is in docker group"' >> /home/developer/.zshrc && \
    echo '    echo "   3. Restart the container after fixing permissions"' >> /home/developer/.zshrc && \
    echo '  fi' >> /home/developer/.zshrc && \
    echo 'fi' >> /home/developer/.zshrc && \
    echo '' >> /home/developer/.zshrc && \
    echo '# Fix common permission issues on startup' >> /home/developer/.zshrc && \
    echo 'mkdir -p /tmp/npm-cache' >> /home/developer/.zshrc && \
    echo 'chmod -R 777 /tmp/npm-cache 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'if [[ -d ~/.npm-global ]]; then' >> /home/developer/.zshrc && \
    echo '  chmod -R 755 ~/.npm-global 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'fi' >> /home/developer/.zshrc && \
    echo 'if [[ -d ~/.local/bin ]]; then' >> /home/developer/.zshrc && \
    echo '  chmod -R +x ~/.local/bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'fi' >> /home/developer/.zshrc && \
    echo 'if [[ -d ~/.cargo/bin ]]; then' >> /home/developer/.zshrc && \
    echo '  chmod -R +x ~/.cargo/bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'fi' >> /home/developer/.zshrc && \
    echo 'if [[ -d ~/go/bin ]]; then' >> /home/developer/.zshrc && \
    echo '  chmod -R +x ~/go/bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'fi' >> /home/developer/.zshrc

# Set shell history file for zsh
ENV HISTFILE=/home/developer/.zsh_history

# Create an entrypoint script to fix permissions on startup
RUN echo '#!/bin/bash' > /home/developer/entrypoint.sh && \
    echo '# Fix permissions on startup automatically' >> /home/developer/entrypoint.sh && \
    echo 'echo "[ENTRYPOINT] Starting entrypoint script..."' >> /home/developer/entrypoint.sh && \
    echo '' >> /home/developer/entrypoint.sh && \
    echo '# Ensure npm cache directory exists and is writable' >> /home/developer/entrypoint.sh && \
    echo 'rm -rf /tmp/npm-cache 2>/dev/null || true' >> /home/developer/entrypoint.sh && \
    echo 'mkdir -p /tmp/npm-cache' >> /home/developer/entrypoint.sh && \
    echo 'chmod -R 777 /tmp/npm-cache' >> /home/developer/entrypoint.sh && \
    echo '' >> /home/developer/entrypoint.sh && \
    echo '# Create npmrc' >> /home/developer/entrypoint.sh && \
    echo 'cat > ~/.npmrc << EOF' >> /home/developer/entrypoint.sh && \
    echo 'cache=/tmp/npm-cache' >> /home/developer/entrypoint.sh && \
    echo 'prefix=/home/developer/.npm-global' >> /home/developer/entrypoint.sh && \
    echo 'fund=false' >> /home/developer/entrypoint.sh && \
    echo 'audit=false' >> /home/developer/entrypoint.sh && \
    echo 'progress=false' >> /home/developer/entrypoint.sh && \
    echo 'EOF' >> /home/developer/entrypoint.sh && \
    echo '' >> /home/developer/entrypoint.sh && \
    echo '# Auto-install dependencies for all projects' >> /home/developer/entrypoint.sh && \
    echo 'if [[ -d /workspace/projects ]]; then' >> /home/developer/entrypoint.sh && \
    echo '  for project in /workspace/projects/*; do' >> /home/developer/entrypoint.sh && \
    echo '    if [[ -f "$project/package.json" ]]; then' >> /home/developer/entrypoint.sh && \
    echo '      echo "Installing dependencies for $(basename $project)..."' >> /home/developer/entrypoint.sh && \
    echo '      cd "$project"' >> /home/developer/entrypoint.sh && \
    echo '      # Clean up any existing node_modules with wrong permissions' >> /home/developer/entrypoint.sh && \
    echo '      rm -rf node_modules package-lock.json 2>/dev/null || true' >> /home/developer/entrypoint.sh && \
    echo '      # Install dependencies' >> /home/developer/entrypoint.sh && \
    echo '      npm install --no-audit --no-fund --cache=/tmp/npm-cache 2>/dev/null || true' >> /home/developer/entrypoint.sh && \
    echo '      # Fix permissions' >> /home/developer/entrypoint.sh && \
    echo '      if [[ -d node_modules/.bin ]]; then' >> /home/developer/entrypoint.sh && \
    echo '        find node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true' >> /home/developer/entrypoint.sh && \
    echo '      fi' >> /home/developer/entrypoint.sh && \
    echo '    fi' >> /home/developer/entrypoint.sh && \
    echo '  done' >> /home/developer/entrypoint.sh && \
    echo '  # Run comprehensive permission fix after all installs' >> /home/developer/entrypoint.sh && \
    echo '  /home/developer/bin/fix-jest-permissions.sh 2>/dev/null || true' >> /home/developer/entrypoint.sh && \
    echo 'fi' >> /home/developer/entrypoint.sh && \
    echo '' >> /home/developer/entrypoint.sh && \
    echo '# Fix Docker socket permissions if needed' >> /home/developer/entrypoint.sh && \
    echo 'if [[ -S /var/run/docker.sock ]]; then' >> /home/developer/entrypoint.sh && \
    echo '  echo "[DOCKER] Docker socket found, checking permissions..."' >> /home/developer/entrypoint.sh && \
    echo '  # Get the group ID of the docker socket' >> /home/developer/entrypoint.sh && \
    echo '  DOCKER_GID=$(stat -c "%g" /var/run/docker.sock)' >> /home/developer/entrypoint.sh && \
    echo '  echo "[DOCKER] Docker socket GID: $DOCKER_GID"' >> /home/developer/entrypoint.sh && \
    echo '  # Check current user groups' >> /home/developer/entrypoint.sh && \
    echo '  echo "[DOCKER] Current user: $(whoami)"' >> /home/developer/entrypoint.sh && \
    echo '  echo "[DOCKER] Current groups: $(id -G)"' >> /home/developer/entrypoint.sh && \
    echo '  # Check if docker group exists with correct GID' >> /home/developer/entrypoint.sh && \
    echo '  CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "")' >> /home/developer/entrypoint.sh && \
    echo '  if [ "$DOCKER_GID" != "$CURRENT_DOCKER_GID" ]; then' >> /home/developer/entrypoint.sh && \
    echo '    echo "[DOCKER] Docker socket GID is $DOCKER_GID, but docker group GID is $CURRENT_DOCKER_GID"' >> /home/developer/entrypoint.sh && \
    echo '    # Try to create a new group with the correct GID' >> /home/developer/entrypoint.sh && \
    echo '    sudo groupadd -g $DOCKER_GID docker-host 2>/dev/null && echo "[DOCKER] Created docker-host group" || echo "[DOCKER] Failed to create docker-host group"' >> /home/developer/entrypoint.sh && \
    echo '    sudo usermod -aG docker-host developer 2>/dev/null && echo "[DOCKER] Added to docker-host group" || echo "[DOCKER] Failed to add to docker-host group"' >> /home/developer/entrypoint.sh && \
    echo '  fi' >> /home/developer/entrypoint.sh && \
    echo '  # Check if we can access Docker socket' >> /home/developer/entrypoint.sh && \
    echo '  if ! docker version >/dev/null 2>&1; then' >> /home/developer/entrypoint.sh && \
    echo '    echo "[DOCKER] Still cannot access Docker socket."' >> /home/developer/entrypoint.sh && \
    echo '    echo "[DOCKER] Please add DOCKER_GID=$DOCKER_GID to your .env file and restart the container."' >> /home/developer/entrypoint.sh && \
    echo '  else' >> /home/developer/entrypoint.sh && \
    echo '    echo "[DOCKER] Docker access working!"' >> /home/developer/entrypoint.sh && \
    echo '  fi' >> /home/developer/entrypoint.sh && \
    echo 'fi' >> /home/developer/entrypoint.sh && \
    echo '' >> /home/developer/entrypoint.sh && \
    echo '# Execute the command' >> /home/developer/entrypoint.sh && \
    echo 'exec "$@"' >> /home/developer/entrypoint.sh &&     echo '' >> /home/developer/entrypoint.sh &&     echo '# Set environment variables passed from docker-compose' >> /home/developer/entrypoint.sh &&     echo 'if [ -n "$GOOGLE_CLOUD_PROJECT" ]; then' >> /home/developer/entrypoint.sh &&     echo '  echo "export GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT" >> /home/developer/.zshrc' >> /home/developer/entrypoint.sh &&     echo 'fi' >> /home/developer/entrypoint.sh &&     chmod +x /home/developer/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/home/developer/entrypoint.sh"]

# Create a startup script that runs initialization in background
RUN echo '#!/bin/bash' > /home/developer/startup.sh && \
    echo '# Start initialization in background' >> /home/developer/startup.sh && \
    echo '/home/developer/bin/init-container.sh &' >> /home/developer/startup.sh && \
    echo '# Keep container running' >> /home/developer/startup.sh && \
    echo 'exec tail -f /dev/null' >> /home/developer/startup.sh && \
    chmod +x /home/developer/startup.sh

# Keep container running
CMD ["/home/developer/startup.sh"]
