#!/bin/bash

# Host-side helper to install/run Playwright MCP (https://github.com/microsoft/playwright-mcp)
# Usage:
#   ./scripts/playwright-mcp.sh install   # install globally via npm
#   ./scripts/playwright-mcp.sh run [args]# run playwright-mcp with optional args
#   ./scripts/playwright-mcp.sh status    # show versions and paths
#   ./scripts/playwright-mcp.sh uninstall # uninstall global package

set -e

# 4-space indent + snake_case per repo conventions

log_info()  { echo -e "[INFO]  $1"; }
log_warn()  { echo -e "[WARN]  $1"; }
log_error() { echo -e "[ERROR] $1"; }

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command '$1' not found on host. Please install it first."
        exit 1
    fi
}

detect_global_prefix_writable() {
    local prefix
    prefix=$(npm prefix -g 2>/dev/null || true)
    if [ -z "$prefix" ]; then
        echo "no"
        return
    fi
    if [ -w "$prefix" ] && [ -w "$prefix/lib" ] && [ -w "/usr/local/bin" ]; then
        echo "yes"
    else
        echo "no"
    fi
}

install_playwright_mcp() {
    require_cmd node
    require_cmd npm

    log_info "Setting npm registry to https://registry.npmjs.org/"
    npm config set registry https://registry.npmjs.org/ >/dev/null 2>&1 || true

    if [ "$(detect_global_prefix_writable)" != "yes" ]; then
        log_warn "npm global prefix not writable. You may need to either:"
        echo "  1) Re-run with sudo (sudo ./scripts/playwright-mcp.sh install)"
        echo "  2) Or configure a user-writable global prefix, e.g.:"
        echo "     npm config set prefix \"$HOME/.npm-global\" && export PATH=\"$HOME/.npm-global/bin:\$PATH\""
        echo "     (add the PATH export to your shell profile)"
    fi

    log_info "Installing Playwright MCP globally (tries multiple sources)..."
    set +e
    log_info "Attempt 1: npm install -g playwright-mcp"
    npm install -g playwright-mcp && ok=1 || ok=0
    if [ "$ok" -ne 1 ]; then
        log_warn "Attempt 1 failed."
        log_info "Attempt 2: npm install -g git+https://github.com/microsoft/playwright-mcp.git"
        npm install -g git+https://github.com/microsoft/playwright-mcp.git && ok=1 || ok=0
    fi
    if [ "$ok" -ne 1 ]; then
        log_warn "Attempt 2 failed."
        log_info "Attempt 3: git clone + npm install -g from local copy"
        tmpdir=$(mktemp -d)
        (cd "$tmpdir" && git clone --depth=1 https://github.com/microsoft/playwright-mcp.git repo && cd repo && npm install -g .)
        ok=$?
        rm -rf "$tmpdir"
    fi
    set -e
    if [ "$ok" -ne 1 ]; then
        log_error "Failed to install Playwright MCP via npm. Check network/permissions and retry."
        exit 1
    fi

    # Ensure browsers installed for Playwright
    if command -v npx >/dev/null 2>&1; then
        log_info "Ensuring Playwright Chromium is installed..."
        set +e
        npx -y playwright@latest install chromium >/dev/null 2>&1 || npx playwright install chromium >/dev/null 2>&1
        set -e
    else
        log_warn "npx not found; skipping 'playwright install chromium'. Install manually if needed."
    fi

    log_info "Installed: $(command -v playwright-mcp || echo 'not on PATH')"
    if command -v playwright-mcp >/dev/null 2>&1; then
        playwright-mcp --version || true
    fi
}

run_playwright_mcp() {
    if ! command -v playwright-mcp >/dev/null 2>&1; then
        log_error "playwright-mcp is not installed. Run: ./scripts/playwright-mcp.sh install"
        exit 1
    fi
    log_info "Running: playwright-mcp $*"
    exec playwright-mcp "$@"
}

status_playwright_mcp() {
    if command -v playwright-mcp >/dev/null 2>&1; then
        echo "playwright-mcp: $(command -v playwright-mcp)"
        playwright-mcp --version || true
    else
        echo "playwright-mcp: not installed"
    fi
    if command -v node >/dev/null 2>&1; then
        echo "node: $(node --version)"
    fi
    if command -v npm >/dev/null 2>&1; then
        echo "npm: $(npm --version)"
        echo "npm prefix -g: $(npm prefix -g 2>/dev/null || echo 'unknown')"
    fi
}

uninstall_playwright_mcp() {
    require_cmd npm
    set +e
    npm rm -g @microsoft/playwright-mcp >/dev/null 2>&1
    npm rm -g playwright-mcp >/dev/null 2>&1
    set -e
    log_info "Uninstall attempted. Current status:"
    status_playwright_mcp
}

cmd=${1:-help}
shift || true

case "$cmd" in
    install)
        install_playwright_mcp "$@"
        ;;
    run)
        run_playwright_mcp "$@"
        ;;
    status)
        status_playwright_mcp
        ;;
    uninstall)
        uninstall_playwright_mcp
        ;;
    help|--help|-h|*)
        cat <<USAGE
Usage:
  ./scripts/playwright-mcp.sh install         Install Playwright MCP globally via npm
  ./scripts/playwright-mcp.sh run [args...]   Run playwright-mcp with optional args
  ./scripts/playwright-mcp.sh status          Show installed paths and versions
  ./scripts/playwright-mcp.sh uninstall       Uninstall the global package

Notes:
  - This is host-side. Do NOT run inside the Docker container.
  - If global install fails due to permissions, either use sudo, or configure a user-writable npm prefix:
      npm config set prefix "$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
USAGE
        ;;
esac
