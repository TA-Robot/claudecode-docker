FROM node:20

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
    && rm -rf /var/lib/apt/lists/*

# Generate Japanese locale
RUN sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# Create custom user and group with explicit UID/GID (Docker group will be added later)
RUN groupadd -g 1000 developer 2>/dev/null || true && \
    (useradd -u 1000 -g 1000 -m -d /home/developer -s /bin/zsh developer 2>/dev/null || \
     usermod -s /bin/zsh -d /home/developer -g 1000 node)

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Docker (Docker-in-Docker support) and add user to docker group
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/* && \
    # Add user to docker group after Docker installation
    usermod -aG docker $(id -nu 1000) 2>/dev/null || usermod -aG docker developer 2>/dev/null || true && \
    # Set Docker socket permissions (will be mounted from host)
    touch /var/run/docker.sock && \
    chgrp docker /var/run/docker.sock && \
    chmod 660 /var/run/docker.sock

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
    && rm -rf /var/lib/apt/lists/*

# Install Rust (as root initially, will be configured for user later)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=\"/root/.cargo/bin:${PATH}\"

# Set npm global permissions and install Claude Code
RUN chown -R 1000:1000 /usr/local/lib/node_modules || true && \
    chmod -R 755 /usr/local/lib/node_modules || true && \
    npm install -g @anthropic-ai/claude-code && \
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

# Configure npm for custom user
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global
ENV NPM_CONFIG_CACHE=/tmp/npm-cache
ENV PATH=$PATH:/home/developer/.npm-global/bin:/home/developer/.local/bin

# Set working directory and create project directories with proper permissions
WORKDIR /workspace
RUN mkdir -p /workspace/projects && \
    chown -R 1000:1000 /workspace && \
    chmod -R 755 /workspace

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

# Install and configure Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

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
    echo 'chmod -R +x ./node_modules/.bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
    echo 'chmod -R +x $HOME/.npm-global/lib/node_modules/.bin/* 2>/dev/null || true' >> /home/developer/.zshrc && \
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
    echo '  # Docker socket should be pre-configured with proper permissions' >> /home/developer/.zshrc && \
    echo '  # If not accessible, contact system administrator' >> /home/developer/.zshrc && \
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
    echo '# Execute the command' >> /home/developer/entrypoint.sh && \
    echo 'exec "$@"' >> /home/developer/entrypoint.sh && \
    chmod +x /home/developer/entrypoint.sh

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