# syntax=docker/dockerfile:1.7

# NOTE TO CODING AGENTS (READ ME FIRST):
# - This Dockerfile is structured to maximize build cache reuse.
# - Add new packages/config at the designated markers ONLY to avoid invalidating
#   upstream layers. Prefer app- or project-level changes outside the image.
# - Keep frequently changing COPY/RUN near the bottom. Do not move them up.

FROM node:20

ARG INSTALL_CODEX=true

# -----------------------------------------------------------------------------
# Base env (stable; rarely changes)
# -----------------------------------------------------------------------------
ENV TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

# Speed up apt using BuildKit cache mounts when available (safe if disabled)
# IMPORTANT: If you add/remove apt packages, do it in the SINGLE block below.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update; \
    # Add Google Cloud SDK apt repo
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list; \
    # Add Docker apt repo (Docker-in-Docker client tools inside container)
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
      > /etc/apt/sources.list.d/docker.list; \
    apt-get update; \
    #
    # APT PACKAGE BLOCK (stable):
    # Add/remove packages here only. Keep the list alphabetized for diff-friendliness.
    #
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      apt-transport-https \
      bash-completion \
      build-essential \
      ca-certificates \
      chromium \
      cmake \
      containerd.io \
      curl \
      default-jdk \
      docker-buildx-plugin \
      docker-ce \
      docker-ce-cli \
      docker-compose-plugin \
      git \
      gnupg \
      google-cloud-cli \
      golang-go \
      htop \
      jq \
      libffi-dev \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libcups2 \
      libgbm1 \
      libgtk-3-0 \
      libpq-dev \
      libnspr4 \
      libnss3 \
      libsqlite3-dev \
      libssl-dev \
      libxdamage1 \
      libxss1 \
      locales \
      lsb-release \
      maven \
      nano \
      netcat-openbsd \
      openssl \
      nginx \
      pkg-config \
      postgresql-client \
      python-is-python3 \
      python3 \
      python3-dev \
      python3-pip \
      python3-venv \
      redis-tools \
      rsync \
      screen \
      software-properties-common \
      sudo \
      tmux \
      tree \
      zlib1g-dev \
      unzip \
      vim \
      wget \
      zip; \
    # locale
    sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    # docker group (common GIDs)
    (groupadd -g 999 docker 2>/dev/null || groupadd -g 998 docker 2>/dev/null || groupadd docker 2>/dev/null || true); \
    # cleanup
    rm -rf /var/lib/apt/lists/*

# Reuse UID 1000 as developer (matches upstream node image)
RUN set -eux; \
    existing_user=$(getent passwd 1000 | cut -d: -f1 || true); \
    if [ -n "$existing_user" ]; then \
      usermod -l developer -d /home/developer -m "$existing_user"; \
      groupmod -n developer "$(id -gn developer)" || true; \
      usermod -s /bin/zsh developer || true; \
    else \
      groupadd -g 1000 developer; \
      useradd -u 1000 -g 1000 -m -d /home/developer -s /bin/zsh developer; \
    fi; \
    usermod -aG docker developer; \
    echo "developer ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/010-developer-all; \
    chmod 0440 /etc/sudoers.d/010-developer-all

# Install Rust (stable, infrequent changes)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Workspace and common dirs (stable)
WORKDIR /workspace
RUN set -eux; \
    install -d -m 0775 /workspace/projects /workspace/logs /workspace/coverage /workspace/test-results; \
    chown -R 1000:1000 /workspace; \
    chmod -R 777 /workspace/logs /workspace/coverage /workspace/test-results

# Pre-create user directories and set permissions (stable)
RUN set -eux; \
    for d in \
      /home/developer/.npm-global \
      /home/developer/.claude \
      /home/developer/.cache/claude \
      /home/developer/.local/bin \
      /home/developer/.cargo \
      /home/developer/.rustup \
      /home/developer/.config \
      /home/developer/.cache/pip \
      /home/developer/.cache/go-build \
      /home/developer/.cache/maven \
      /home/developer/go/bin \
      /home/developer/go/src \
      /home/developer/go/pkg \
      /home/developer/.local/lib/python3.11/site-packages \
      /tmp/developer \
      /home/developer/.venv \
      /home/developer/.pyenv \
      /home/developer/.poetry \
      /home/developer/.pipx \
      /home/developer/.bundle \
      /home/developer/.gem \
      /home/developer/.gradle \
      /home/developer/.m2 \
      /home/developer/.docker \
      /home/developer/.kube \
      /home/developer/.ssh \
      /home/developer/.gnupg \
      /home/developer/.git \
      /home/developer/.gitconfig.d; do \
        install -d -m 0755 "$d"; \
    done; \
    chown -R 1000:1000 /home/developer /workspace /tmp/developer; \
    chmod 700 /home/developer/.ssh /home/developer/.gnupg; \
    chmod 755 /tmp/developer

# Global npm setup and tool installation (stable list; keep here for cache)
# AGENT NOTE: Add/remove global npm CLIs in THIS block only to keep cache hits.
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global \
    NPM_CONFIG_CACHE=/tmp/npm-cache \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

RUN --mount=type=cache,target=/tmp/npm-cache,sharing=locked \
    set -eux; \
    chown -R 1000:1000 /usr/local/lib/node_modules || true; \
    chmod -R 755 /usr/local/lib/node_modules || true; \
    npm config set fund false; \
    npm config set audit false; \
    npm config set prefer-online false; \
    npm config set cache /tmp/npm-cache; \
    pkgs=" \
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
      @anthropic-ai/claude-code \
      @google/gemini-cli \
    "; \
    if [ "$INSTALL_CODEX" = "true" ]; then pkgs="$pkgs @openai/codex"; fi; \
    npm install -g $pkgs || true; \
    chmod -R +x /usr/local/lib/node_modules/.bin/* 2>/dev/null || true; \
    chmod -R +x /usr/local/bin/* 2>/dev/null || true; \
    # Ensure developer owns npm global prefix to allow installs at runtime
    chown -R 1000:1000 /home/developer/.npm-global 2>/dev/null || true

# Switch to developer for user-level setup (stable)
USER 1000
ENV HOME=/home/developer \
    USER=developer \
    PATH=/home/developer/.local/bin:/home/developer/bin:/home/developer/.cargo/bin:/home/developer/.npm-global/bin:$PATH \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_CACHE_DIR=/home/developer/.cache/pip \
    PIP_ROOT_USER_ACTION=ignore
WORKDIR /home/developer

# Oh My Zsh (stable)
RUN for i in 1 2 3; do \
      echo "Attempt $i to install Oh My Zsh..."; \
      curl -fsSL --connect-timeout 30 --max-time 120 \
        https://cdn.jsdelivr.net/gh/ohmyzsh/ohmyzsh@master/tools/install.sh \
        -o /tmp/install_omz.sh && sh /tmp/install_omz.sh --unattended && rm -f /tmp/install_omz.sh && break || (echo "retry..." && sleep 5); \
    done; \
    touch /home/developer/.zshrc

# zshrc configuration (stable)
RUN set -eux; \
    { \
      echo '# Prevent no-match errors'; \
      echo 'setopt null_glob'; \
      echo 'setopt no_nomatch'; \
      echo ''; \
      echo '# Custom environment paths'; \
      echo 'export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$PATH"'; \
      echo 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"'; \
      echo 'export NPM_CONFIG_CACHE="/tmp/npm-cache"'; \
      echo 'export PATH="$PATH:$HOME/.npm-global/bin"'; \
      echo 'export GOPATH="$HOME/go"'; \
      echo 'export PATH="$PATH:$GOPATH/bin"'; \
      echo 'export CARGO_HOME="$HOME/.cargo"'; \
      echo 'export RUSTUP_HOME="$HOME/.rustup"'; \
      echo 'export JAVA_HOME="/usr/lib/jvm/default-java"'; \
      echo 'export MAVEN_HOME="/usr/share/maven"'; \
      echo 'export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"'; \
      echo 'export PIP_USER=1'; \
      echo ''; \
      echo '# npm install helper'; \
      echo 'fix_npm_permissions() { [[ -d ./node_modules/.bin ]] && find ./node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true; }'; \
      echo 'npm() { command npm "$@"; if [[ "$1" == "install" || "$1" == "i" || "$1" == "ci" ]]; then fix_npm_permissions; fi }'; \
      echo ''; \
      echo '# Auto-fix on cd'; \
      echo 'chpwd() {'; \
      echo '  [[ -d ./node_modules/.bin ]] && chmod -R +x ./node_modules/.bin/* 2>/dev/null || true'; \
      echo '  [[ -d ./venv/bin ]] && chmod -R +x ./venv/bin/* 2>/dev/null || true'; \
      echo '  [[ -d ./.venv/bin ]] && chmod -R +x ./.venv/bin/* 2>/dev/null || true'; \
      echo '  [[ -d ./bin ]] && chmod -R +x ./bin/* 2>/dev/null || true'; \
      echo '  [[ -f ./package.json && -d ./node_modules/.bin ]] && find ./node_modules/.bin -type f -exec chmod +x {} \; 2>/dev/null || true'; \
      echo '  [[ -d ./target ]] && find ./target -type f -executable -exec chmod +x {} \; 2>/dev/null || true'; \
      echo '}'; \
      echo ''; \
      echo '# Helper'; \
      echo 'fixperms() {'; \
      echo '  [[ -d node_modules/.bin ]] && chmod -R +x node_modules/.bin/* 2>/dev/null'; \
      echo '  [[ -d ~/.npm-global/lib/node_modules/.bin ]] && chmod -R +x ~/.npm-global/lib/node_modules/.bin/* 2>/dev/null'; \
      echo '  [[ -d venv/bin ]] && chmod -R +x venv/bin/* 2>/dev/null'; \
      echo '  [[ -d .venv/bin ]] && chmod -R +x .venv/bin/* 2>/dev/null'; \
      echo '  [[ -d ~/.local/bin ]] && chmod -R +x ~/.local/bin/* 2>/dev/null'; \
      echo '  [[ -d ~/go/bin ]] && chmod -R +x ~/go/bin/* 2>/dev/null'; \
      echo '  [[ -d ~/.cargo/bin ]] && chmod -R +x ~/.cargo/bin/* 2>/dev/null'; \
      echo '  [[ -d target ]] && find target -type f -executable -exec chmod +x {} \; 2>/dev/null'; \
      echo '  [[ -d bin ]] && chmod -R +x bin/* 2>/dev/null'; \
      echo '  [[ -d scripts ]] && chmod -R +x scripts/* 2>/dev/null'; \
      echo '}'; \
      echo ''; \
      echo '# Prompt and history'; \
      echo 'export PS1="%F{cyan}%n@%m%f:%F{yellow}%~%f$ "'; \
      echo 'setopt PROMPT_SUBST'; \
      echo 'export PROMPT_DIRTRIM=0'; \
      echo 'HISTSIZE=10000'; \
      echo 'SAVEHIST=10000'; \
      echo 'setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY'; \
      echo ''; \
      echo '# Completion'; \
      echo 'setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END'; \
      echo 'zstyle ":completion:*" menu select'; \
      echo 'zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"'; \
      echo ''; \
      echo '# Docker socket hint'; \
      echo 'if [[ -S /var/run/docker.sock ]] && ! docker version >/dev/null 2>&1; then'; \
      echo '  echo "⚠️  Docker socket is not accessible. Check mount/permissions."'; \
      echo 'fi'; \
      echo ''; \
      echo '# Startup fixes'; \
      echo 'mkdir -p /tmp/npm-cache && chmod -R 777 /tmp/npm-cache 2>/dev/null || true'; \
      echo '[[ -d ~/.npm-global ]] && chmod -R 755 ~/.npm-global 2>/dev/null || true'; \
      echo '[[ -d ~/.local/bin ]] && chmod -R +x ~/.local/bin/* 2>/dev/null || true'; \
      echo '[[ -d ~/.cargo/bin ]] && chmod -R +x ~/.cargo/bin/* 2>/dev/null || true'; \
      echo '[[ -d ~/go/bin ]] && chmod -R +x ~/go/bin/* 2>/dev/null || true'; \
    } >> /home/developer/.zshrc

ENV HISTFILE=/home/developer/.zsh_history

# Entrypoint-like startup helper (stable)
RUN set -eux; \
    mkdir -p /home/developer/bin; \
    cat > /home/developer/entrypoint.sh <<'EOF'
#!/bin/bash
set -euo pipefail
echo "[ENTRYPOINT] Preparing workspace..."
rm -rf /tmp/npm-cache 2>/dev/null || true
mkdir -p /tmp/npm-cache && chmod -R 777 /tmp/npm-cache
mkdir -p ~/.npm-global/lib/node_modules ~/.npm-global/bin
[[ -d ~/.local/bin ]] || mkdir -p ~/.local/bin
exit 0
EOF
RUN chmod +x /home/developer/entrypoint.sh

# -----------------------------------------------------------------------------
# DYNAMIC SECTION (changes often; keep at bottom)
# -----------------------------------------------------------------------------
# AGENT NOTE: Place COPY of local config/content BELOW this line to avoid
# busting cache of the heavy layers above. Only touch below unless absolutely
# necessary.

# Switch to root for dynamic copies and permissions
USER root

# Copy default configuration (these files change relatively often)
COPY claude-config/ /home/developer/.claude/
COPY .npmrc.template /home/developer/.npmrc
COPY scripts/fix-npm-permissions.sh /home/developer/bin/
COPY scripts/init-container.sh /home/developer/bin/
COPY scripts/fix-jest-permissions.sh /home/developer/bin/
COPY scripts/python-dev-venv.sh /home/developer/bin/
RUN chmod +x /home/developer/bin/fix-npm-permissions.sh \
         /home/developer/bin/init-container.sh \
         /home/developer/bin/fix-jest-permissions.sh \
         /home/developer/bin/python-dev-venv.sh && \
    chown -R 1000:1000 /home/developer/.claude /home/developer/bin /home/developer/.npmrc

# Return to developer user
USER 1000

# Final working dir inside container
WORKDIR /workspace
