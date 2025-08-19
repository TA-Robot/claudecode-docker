# Codex CLI Configuration for AI Code Docker Environment

This repository supports running Codex CLI inside the same Docker environment used for Claude Code and Gemini CLI.

## Requirements

- Host-side credentials are preferred and auto-synced:
  - `~/.codex` is auto-copied into the container via `./codex-config` mount
  - `~/.config/openai` is mounted read-only to `/home/developer/.config/openai`
  - `OPENAI_API_KEY` in `.env` is optional; use if you prefer env-based auth

## Install Codex CLI

### 自動インストール（推奨・npm 最新）

以下のコマンドでCLIが未インストールの場合、自動的に導入を試みます（npm導入→ラッパー自動生成→ホストからのコピーの順）。

```
./dev.sh start
./dev.sh codex
```

### 手動インストール（npm 推奨・最新）

コンテナ内で、以下のいずれかを実行してください：

```
./dev.sh shell

# npm（推奨・最新）
npm config set registry https://registry.npmjs.org/
npm install -g @openai/codex

# Verify
codex --version
```

Notes:
- CLIの配布方法は変更されうるため、最新の公式手順に従ってください。
- APIキーは `OPENAI_API_KEY` を利用します（`.env` に設定）。

## Usage

Start the environment, then launch Codex CLI:

```
./dev.sh start
./dev.sh codex
```

Resolution order if CLI is not found:
- Try auto-install (npm latest)
- If PATH not resolved, wrapper `/usr/local/bin/codex` is generated to point at installed package
- If host has `@openai/codex`, the package is copied into the container and wrapper is created
- Otherwise the command opens an interactive shell and shows installation hints

## Configuration

- Host path `codex-config/` is mounted to container path `/home/developer/.codex`.
- Example config file: `codex-config/settings.json`.
- Workspaces are under `/workspace/projects` (mounted from `./projects`).

## Troubleshooting

- Ensure `OPENAI_API_KEY` is present in `.env` before starting the environment.
- Inside container, confirm network access and that `codex` binary is on `PATH`.
- See `README.md` and `DEVELOPMENT_STATUS.md` for general environment guidance.
