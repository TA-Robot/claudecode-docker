#!/usr/bin/env bash
set -euo pipefail

# Create and use a Python venv inside the dev container without touching project files.
# - Creates venv under /home/developer/.venvs/<name>
# - Optionally installs a project in editable mode with [dev] extras if present
#
# Usage:
#   python-dev-venv.sh <name> [project_path]
#   python-dev-venv.sh pm /workspace/projects/pm
#
# Notes:
# - Safe to re-run; upgrades pip and reuses existing venv
# - Prints activation hint at the end

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <name> [project_path]" >&2
  exit 1
fi

NAME="$1"
PROJ_PATH="${2:-}"

VENV_BASE="$HOME/.venvs"
VENV_DIR="$VENV_BASE/$NAME"

mkdir -p "$VENV_BASE"

if [[ ! -d "$VENV_DIR" ]]; then
  echo "[pyvenv] Creating venv: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  echo "[pyvenv] Reusing existing venv: $VENV_DIR"
fi

# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"
python -m pip install -q -U pip setuptools wheel

if [[ -n "$PROJ_PATH" ]]; then
  if [[ -f "$PROJ_PATH/pyproject.toml" ]]; then
    echo "[pyvenv] Installing project (editable): $PROJ_PATH"
    # Try [dev] extra first; fall back to plain editable if extras missing
    pip install -q -e "$PROJ_PATH[dev]" || pip install -q -e "$PROJ_PATH"
  else
    echo "[pyvenv] Warn: pyproject.toml not found at $PROJ_PATH (skipping install)"
  fi
fi

echo
echo "[pyvenv] Done. To activate:"
echo "  source $VENV_DIR/bin/activate"
echo
