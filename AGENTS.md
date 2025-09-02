# Repository Guidelines

## Project Structure & Module Organization
- `projects/`: Your app code lives here. Each subfolder is an isolated project mounted into the container.
- `claude-config/`: Agent settings (e.g., `settings.json`) applied inside the dev container.
- `scripts/`: Host-side utility scripts (setup, tests, fixes).
- Root files: `Dockerfile`, `docker-compose.yml`, `.env(.example)`, `dev.sh`, `setup.sh`.

### 開発対象スコープ（重要）
- `projects/` 直下の各サブディレクトリ（例: `projects/pm`）は、この開発環境テンプレートを“利用する”別個のアプリケーション/プロジェクトです。
- 本リポジトリの開発対象は、環境スクリプト・Docker 構成・共通ドキュメント等（このテンプレート自体）に限定します。`projects/<name>` の実装は原則対象外です。
- もし `projects/<name>` に変更が必要な場合は、そのプロジェクトを明示した独立タスク/PRとして取り扱い、本テンプレート改修とは分離してください。
- 誤って `projects/` 直下を編集・コミットに含めないよう、作業ブランチやPRの範囲を確認してください。

## Build, Test, and Development Commands
- `./setup.sh`: One-time environment setup (installs/validates Docker, creates `.env`).
- `./dev.sh start|stop|restart|status`: Manage the development stack.
- `./dev.sh shell`: Open a shell in the dev container.
- `./dev.sh claude` / `./dev.sh gemini`: Launch Claude Code or Gemini CLI inside the container.
- `./dev.sh build|clean|logs|env`: Rebuild, clean artifacts, view logs, check env.
- Tests: `./dev.sh test` (full), `./scripts/quick-test.sh`, `./scripts/test-local.sh`, `./scripts/test.sh`.
- Docker (advanced): `docker-compose up -d`, `docker-compose exec claude-dev bash`.

## Coding Style & Naming Conventions
- Shell scripts: Bash with `set -e` (match existing), 4-space indent, functions in `snake_case`.
- Filenames: kebab-case with `.sh` (e.g., `setup-minimal.sh`, `test-local.sh`).
- Config: JSON files with 2-space indent; keep comments in docs, not JSON.
- Environment vars: UPPER_CASE, document in `.env.example` when introducing new keys.

## Testing Guidelines
- Smoke tests live in `scripts/` and are runnable from the host.
- Before opening a PR, run: `./dev.sh test` and, if Docker is unavailable, `./scripts/test-local.sh`.
- Add minimal verifications for new scripts to `scripts/test.sh` and update `scripts/README.md`.

## Commit & Pull Request Guidelines
- Commits: short imperative summaries; English or Japanese accepted (e.g., "gemini追加", "権限周りを修正").
- Branch naming: `feat/…`, `fix/…`, or `chore/…` when practical.
- PRs must include: purpose, key changes, how to run/test (`./dev.sh start`, `./dev.sh test`), and any docs updated (`README.md`, this file).
- Link related issues; include screenshots/log snippets when behavior or setup changes.

## Security & Configuration Tips
- Do not commit secrets. Use `.env` (create from `.env.example`).
- For Docker-in-Docker, set `DOCKER_GID` in `.env` per the README and restart via `./dev.sh restart`.
- Update `.env.example` and the README when adding new required configuration.

## Agent-Specific Notes
- Claude Code: `./dev.sh claude`; per-project guidance in `projects/CLAUDE.md`.
- Gemini CLI: `./dev.sh gemini` (ensure local `gcloud auth application-default login`).

## Codex CLI

This repository supports running Codex CLI alongside Claude Code and Gemini CLI.

### Requirements
- Prefer host-side auth synced into the container:
  - `~/.codex` is auto-copied via `./codex-config` mount
  - `~/.config/openai` is mounted read-only to `/home/developer/.config/openai`
  - `OPENAI_API_KEY` in `.env` is optional (env-based auth)

### Install
- Auto attempt (recommended):
  - `./dev.sh start && ./dev.sh codex`
  - If not found, the script prints install hints and opens a shell
- Manual (inside container):
  - `npm config set registry https://registry.npmjs.org/`
  - `npm install -g @openai/codex`
  - Verify: `codex --version`

Notes:
- Distribution may change; follow official instructions if the package name changes.
- Uses `OPENAI_API_KEY` if set.

### Usage
- Start env, then launch Codex CLI:
  - `./dev.sh start`
  - `./dev.sh codex`
- If CLI is missing, resolution order:
  - Try auto-install (npm latest)
  - Create `/usr/local/bin/codex` wrapper if needed
  - Copy host `@openai/codex` package if available
  - Otherwise open an interactive shell with hints

### Configuration
- Host `codex-config/` → container `/home/developer/.codex`
- Workspaces in `/workspace/projects` (from `./projects`)

### Troubleshooting
- Ensure `OPENAI_API_KEY` in `.env` if using env-based auth
- Inside container, verify network and that `codex` is on PATH
- See `README.md` and `DEVELOPMENT_STATUS.md` for environment guidance
