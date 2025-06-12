FROM node:20

# Set timezone and locale
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# Install development tools and locale support
RUN apt-get update && apt-get install -y \
    git \
    zsh \
    fzf \
    jq \
    unzip \
    curl \
    vim \
    nano \
    bash-completion \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate Japanese locale
RUN sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# Create custom user and group with explicit UID/GID
RUN groupadd -g 1000 developer || true && \
    useradd -u 1000 -g 1000 -m -d /home/developer -s /bin/zsh developer || \
    usermod -s /bin/zsh -d /home/developer node

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Configure npm for custom user
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global
ENV PATH=$PATH:/home/developer/.npm-global/bin

# Set working directory
WORKDIR /workspace

# Create directories with proper permissions
RUN mkdir -p /workspace/projects && \
    mkdir -p /home/developer/.npm-global && \
    mkdir -p /home/developer/.claude && \
    mkdir -p /home/developer/.cache/claude && \
    mkdir -p /home/developer/.npm && \
    chown -R 1000:1000 /home/developer && \
    chown -R 1000:1000 /workspace

# Copy default configuration
COPY claude-config/ /home/developer/.claude/
RUN chown -R 1000:1000 /home/developer/.claude/ && \
    chmod -R 755 /home/developer/.claude/

# Switch to user with UID 1000
USER 1000

# Install and configure Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

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
    echo 'alias egrep="egrep --color=auto"' >> /home/developer/.zshrc

# Set shell history file for zsh
ENV HISTFILE=/home/developer/.zsh_history

# Keep container running
CMD ["tail", "-f", "/dev/null"]