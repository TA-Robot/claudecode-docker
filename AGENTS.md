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

### Web Search via Gemini CLI (for Codex Agent)
- Goal: Codex delegates web search to Gemini CLI and returns results with citations
- Rules:
  - Always use `gemini -p "<指示>"` for web search
  - Do not fetch pages directly with curl; let Gemini browse
  - Always include source URLs and access日時 in answers
- How to use (direct):
  - Enter container: `./dev.sh shell`
  - Examples:
    - General search: `gemini -p "Search the web for <topic>. Return 5–8 credible sources with title, URL, brief summaries, and include access date."`
    - Fresh news: `gemini -p "Search the web for the latest updates about <topic> (past 30 days). Provide 5–8 reputable sources and include access date."`
    - Docs lookup: `gemini -p "Search the web for the official documentation of <library>. Provide key links with titles and URLs, plus relevance notes. Include access date."`
- Operational notes:
  - Host `~/.config/gcloud` is mounted read-only; `~/.gemini` is copied on `./dev.sh start`
  - Save logs under `/workspace/logs` if needed
- Caching tip: do not modify Dockerfile for search; use run-time `gemini -p` to keep image cache effective

#### Approval-Aware Protocol (Codex CLI)
When performing web search from this harness (sandboxed, approvals on-request):

1) Confirm scope: Clarify topic, timeframe, and language. If unspecified, propose a sensible default and ask for consent.
2) Prefer host `gemini`: First check `command -v gemini`; if available, use it directly instead of starting the container.
3) Ask once for approval before networked commands: Explain the exact `gemini -p` you will run and request approval to execute it.
4) Minimal privileges: Do not start Docker or modify the environment unless strictly required. Avoid `./dev.sh start` unless the user explicitly asks to work inside the container.
5) If approval is denied/unavailable: Provide a ready-to-copy `gemini -p "…"` command and ask the user to run it, then paste results.
6) Always return citations: Include source URLs and access日時 (JST) in answers per the rules above.

#### Common Pitfalls (and fixes)
- Unnecessary container start: Do not call `./dev.sh start` just to run web search. Use host `gemini` if present.
- Over-escalation: Avoid requesting escalated permissions for Docker operations when not needed. Only ask for approval to run the `gemini -p` command itself.
- Skipping availability check: Always probe `gemini` availability first (`command -v gemini`).
- Missing citations/timestamps: Ensure every item includes URL and `アクセス日時 (YYYY-MM-DD HH:mm JST)`.
- Not following user intent: Confirm topic/timeframe; if the user says “なんでもいい”, default to a 24h world top-news search in Japanese.

#### Standard Prompt Templates
- News (JP, last 24h):
  `gemini -p "最新の世界の主要ニュースを過去24時間に限定してWeb検索してください。6〜8件の信頼できるメディアを選び、各項目に(1)見出し、(2)要点の短い要約(2-3文)、(3)出典のURL、(4)アクセス日時(日本時間, YYYY-MM-DD HH:mm JST)を含めてください。偏りを避け、重複を省き、発表時刻が分かる場合は記載。最後に全体のトレンドを3-5行で簡潔にまとめてください。日本語で回答。"`
- News (EN, last 24h):
  `gemini -p "Search the web for the top world news from the past 24 hours. Return 6–8 reputable sources; for each include: (1) headline, (2) 2–3 sentence summary, (3) source URL, (4) access date/time in JST (YYYY-MM-DD HH:mm JST). Avoid duplicates and note publication times when available. Conclude with a 3–5 line trend summary."`

These templates should be adapted to the user’s requested topic/timeframe/language and always return URLs with access日時.

#### Proactive Search Policy（強化指針）
- 次の状況では、既存の Approval-Aware Protocol に従い、原則として Gemini 検索を発火すること。
  - 最新情報や仕様変更の可能性が高い領域（API/SDK バージョン、ライセンス、脆弱性、クラウド料金/制限）。
  - 初見/不明なエラー、スタックトレース、再現が難しい不具合の切り分け時。
  - 自信度が低い（根拠が薄い）と判断した場合、または複数解法のトレードオフ比較が必要な場合。
  - セキュリティ/コンプライアンスに影響する判断（権限、秘密情報、ネットワーク到達性など）。
  - 外部サービス/CLI のフラグ・環境変数・設定キーの正確性検証が必要な場合（例: タイムアウト/リトライ設定）。
  - 非標準/特殊環境（OSディストリ、アーキテクチャ、社内ミラー等）でのインストール・運用手順の差異確認。
- 実施時の原則:
  - 1回の承認で必要最小限の検索をまとめて実行（連続承認は避ける）。
  - 回答には常に根拠（URL＋アクセス日時JST）を付す。確証が弱い場合はその旨を明記。
  - 公式一次情報（公式Docs/リリースノート/Issue/PR）を優先し、ブログ/フォーラムは補助根拠として扱う。
