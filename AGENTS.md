# Repository Guidelines

## Project Structure & Module Organization
- `projects/`: Your app code lives here. Each subfolder is an isolated project mounted into the container.
- `claude-config/`: Agent settings (e.g., `settings.json`) applied inside the dev container.
- `scripts/`: Host-side utility scripts (setup, tests, fixes).
- Root files: `Dockerfile`, `docker-compose.yml`, `.env(.example)`, `dev.sh`, `setup.sh`.

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
