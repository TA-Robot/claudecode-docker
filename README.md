# AI Code Docker Development Environment

Docker上でClaude CodeとGemini CLIを使用するための統一開発環境テンプレートです。

## 最新バージョン: v1.5.0

### 🆕 v1.5.0の主な変更点
- **開発サービス統合**: PostgreSQL, Redis, Elasticsearch を標準搭載
- **E2Eテスト対応**: Chromium browser と Playwright 環境を事前設定
- **Docker権限改善**: Docker-in-Docker の権限問題を自動解決
- **開発ツール追加**: nginx, netcat, redis-tools などを追加

## 特徴

- **マルチAI対応**: Claude CodeとGemini CLIをシームレスに切り替え可能
- **共通Dockerイメージ**: 複数プロジェクトで同じイメージを共有
- **プロジェクト分離**: 各ディレクトリのprojects/は独立してマウント
- **自動コンテナ識別**: ディレクトリパスのハッシュでコンテナを自動識別
- **同時起動対応**: 複数のclaudecode-dockerディレクトリを同時に使用可能
- **フルスタック開発対応**: DB, Cache, 検索エンジンを含む完全な開発環境

## 開発対象スコープ（重要）
- `projects/` 直下の各サブディレクトリ（例: `projects/pm`）は、本テンプレートを“利用する”個別のアプリケーション/プロジェクトです。
- 本リポジトリの開発対象は、テンプレート（環境スクリプト、Docker 構成、共通ドキュメント等）に限定します。`projects/<name>` のアプリケーション実装は原則対象外です。
- `projects/<name>` に変更が必要な場合は、そのプロジェクトを明示した独立タスク/PRとして取り扱い、本テンプレートの改修とは分離してください。
- PR 作成時は、誤って `projects/` 配下の差分が混入していないかを確認してください。

## クイックスタート

### 1. セットアップ
```bash
# 自動セットアップ（推奨）
./setup.sh

# または管理スクリプトを使用
./dev.sh setup
```

### 2. 環境設定
```bash
# .envファイルを作成（自動で作成されます）
# .envファイルは任意です（ホストの認証情報を自動コピー/マウントします）
# 追加で環境変数を使いたい場合のみ編集:
# - ANTHROPIC_API_KEY (Claude Code用, 任意)
# - GOOGLE_CLOUD_PROJECT (Gemini CLI用, 任意)
# - OPENAI_API_KEY (Codex CLI用, 任意)

# ホスト側での認証設定（推奨）
# - Claude:   ~/.claude を整備 → 自動コピー
# - Gemini:   gcloud ADC (~/.config/gcloud) を自動マウント、~/.gemini は自動コピー
# - OpenAI/Codex: ~/.config/openai を自動マウント、~/.codex は自動コピー
# これによりコンテナ内でのログイン作業は不要です
```

### 3. 開発開始
```bash
# 環境を起動してClaude Codeを開始
./dev.sh claude

# Gemini CLIを開始
./dev.sh gemini

# Codex CLIを開始（CLIのインストールが必要な場合あり）
./dev.sh codex

# または、コンテナに入って手動で作業
./dev.sh shell
```

## セットアップ詳細

### 自動セットアップ（推奨）

#### Linux/macOS
```bash
# フルセットアップ（Docker自動インストール）
./setup.sh

# 最小セットアップ（Dockerが既にある場合）  
./scripts/setup-minimal.sh
```

#### Windows
```powershell
# PowerShellを管理者権限で実行
.\scripts\setup-windows.ps1
```

### 手動セットアップ

#### 1. Claude Code設定
デフォルトで以下の設定が適用されます：
- 基本的なコマンド（npm, git, python等）は自動承認
- ファイル操作（読み取り、書き込み、編集）は自動承認
- システム管理コマンドのみ確認が必要

#### 2. 環境変数の設定
```bash
cp .env.example .env
```
`.env` ファイルを編集して、`ANTHROPIC_API_KEY`と`GEMINI_API_KEY`を設定してください。

##### コンテナ向けシークレット環境変数
- ホスト側で `~/secret/.env.container`（`.env` 形式）を用意すると、`./dev.sh start` や `./dev.sh codex` 実行時に自動で読み込まれ、`claude-dev` コンテナ内の環境変数として反映されます。
- 形式は通常の `.env` と同じで `KEY=value` 行のみを記述してください（コメントや空行は無視されます）。
- デフォルトの場所を変更したい場合は、コマンド実行前に `export CLAUDE_CONTAINER_ENV_FILE=/absolute/path/to/env` を指定します（`~` や相対パスでも可、スクリプトが絶対パスへ解決します）。
- ファイルを更新した場合はコンテナを再起動してください（`./dev.sh restart`）。

#### 3. コンテナのビルドと起動
```bash
# 初回ビルド（共通イメージを作成）
./dev.sh build

# 環境起動
./dev.sh start
```

#### 4. コンテナに入る
```bash
./dev.sh shell
# コンテナ内で作業開始
```

## 複数プロジェクトでの使用

### 共通イメージを使った複数環境
```bash
# プロジェクト1
cd /path/to/claudecode-docker-1
./dev.sh start  # コンテナ名: claude-XXXXXXXX-claude-dev-1

# プロジェクト2（同時起動可能）
cd /path/to/claudecode-docker-2
./dev.sh start  # コンテナ名: claude-YYYYYYYY-claude-dev-1
```

### 外部共通イメージの使用
```bash
# 共通イメージを指定
export CLAUDE_DOCKER_IMAGE="my-shared-claude:latest"
./dev.sh start
```

## 使用方法

### dev.sh - メイン管理スクリプト

```bash
# 環境管理
./dev.sh start          # 環境起動
./dev.sh stop           # 環境停止
./dev.sh restart        # 環境再起動
./dev.sh status         # 状態確認

# 開発作業
./dev.sh shell          # コンテナに入る
./dev.sh claude         # Claude Code直接起動
./dev.sh logs           # ログ表示

# メンテナンス
./dev.sh build          # コンテナ再ビルド
./dev.sh clean          # クリーンアップ
./dev.sh test           # テスト実行
./dev.sh env            # 環境チェック
```

### Playwright MCP（ホスト側セットアップ）
```bash
# インストール（npm グローバル。必要なら sudo を付与）
./scripts/playwright-mcp.sh install

# 起動（引数はそのまま渡せます）
./scripts/playwright-mcp.sh run --help

# 状態確認
./scripts/playwright-mcp.sh status
```

### プロジェクトの作成
```bash
# 環境に入る
./dev.sh shell

# プロジェクト作成（コンテナ内）
cd /workspace/projects
mkdir my-new-project
cd my-new-project

# Claude Code起動
claude
```

### ファイル編集
`./projects/` ディレクトリはホストマシンとマウントされているため、お好みのエディタで編集できます。

## Web閲覧 (MCP) 対応: Playwright MCP（ホスト）

- 目的: Claude Code 等の MCP クライアントから Playwright を用いた Web 閲覧ツールをホスト側で利用可能にする。
- セットアップ/実行: 上記「Playwright MCP（ホスト側セットアップ）」を参照。
- MCPクライアント設定例（参考）:
  - コマンド起動型 MCP クライアントに `playwright-mcp` を登録（command: `playwright-mcp`）。
  - 具体的な登録手順はクライアント側ドキュメントに従ってください。

## マルチプロジェクト対応 (v1.4.0+)

同一ホストで複数の独立したプロジェクトを管理できます。

### アーキテクチャ

```
共通Dockerイメージ: claude-code:latest
          ↓
claudecode-docker-1/
├── projects/     → コンテナ: claude-XXXXXXXX-claude-dev-1
├── cache/        → マウント先: /workspace/projects
└── dev.sh

claudecode-docker-2/
├── projects/     → コンテナ: claude-YYYYYYYY-claude-dev-1
├── cache/        → マウント先: /workspace/projects
└── dev.sh
```

- **共通イメージ**: すべてのプロジェクトで`claude-code:latest`を使用
- **コンテナ識別**: ディレクトリパスのハッシュで自動的にユニークなコンテナ名を生成
- **プロジェクト分離**: 各ディレクトリの`projects/`フォルダは独立してマウント
- **同時起動対応**: 複数のclaudecode-dockerディレクトリを同時に使用可能（ネットワーク名もComposeプロジェクト単位で分離）

### 多重起動時のポート割り当て（自動化）
- ディレクトリパスのハッシュから `PORT_OFFSET` を決定し、以下の公開ポートを自動でユニーク化します。
  - `HOST_PORT_FE = 3001 + PORT_OFFSET`
  - `HOST_PORT_BE = 4001 + PORT_OFFSET`
  - `HOST_PORT_MCP = 5001 + PORT_OFFSET`
  - `HOST_PORT_PG = 5433 + PORT_OFFSET`
  - `HOST_PORT_REDIS = 6380 + PORT_OFFSET`
  - `HOST_PORT_ES_HTTP = 9201 + PORT_OFFSET`
  - `HOST_PORT_ES_TRANSPORT = 9301 + PORT_OFFSET`
- `./dev.sh start` 実行時に計算され、`./docker-compose.yml` のポートに反映されます。
- 実際の割り当ては `./dev.sh status` で確認できます。
- 任意で固定したい場合は `.env` またはシェル環境で上記 `HOST_PORT_*` 変数や `PORT_OFFSET` を事前に指定してください。

## ディレクトリ構造

```
claudecode-docker/
├── Dockerfile              # Claude Code環境の定義
├── docker-compose.yml      # コンテナ設定
├── .env.example            # 環境変数テンプレート
├── .gitignore              # Git無視ファイル
├── projects/               # 開発プロジェクト（ホストとマウント）
│   ├── .project-name       # プロジェクト識別ファイル（オプション）
│   └── CLAUDE.md           # Claude Code設定テンプレート（TDD・履歴管理ルール含む）
├── claude-config/          # Claude Code設定ディレクトリ
│   └── settings.json       # 自動承認設定
├── codex-config/           # Codex CLI設定ディレクトリ
│   └── settings.json       # Codex CLI設定
├── cache/                  # キャッシュディレクトリ
├── dev.sh                  # メイン管理スクリプト
├── setup.sh                # セットアップ（wrapper）
├── scripts/                # 管理スクリプト集
│   ├── setup.sh            # メインセットアップ（Linux/macOS）
│   ├── setup-windows.ps1   # Windowsセットアップ
│   ├── setup-minimal.sh    # 最小セットアップ
│   ├── install-compose.sh  # Docker Compose個別インストール
│   ├── test.sh             # フル環境テスト
│   ├── test-local.sh       # ローカル設定検証
│   ├── quick-test.sh       # クイック検証
│   └── README.md           # スクリプト説明
├── DEVELOPMENT_STATUS.md   # 開発状況・履歴
└── README.md               # このファイル
```

## 含まれるサービス (v1.5.0)

| サービス | ポート | 用途 |
|---------|--------|------|
| Claude Dev | 3000, 4000, 5000 | Frontend, Backend API, MCP Server |
| PostgreSQL 14 | 5432 | リレーショナルデータベース |
| Redis 7 | 6379 | キャッシュ・セッション管理 |
| Elasticsearch 8.11.3 | 9200, 9300 | 全文検索エンジン |

### 環境変数（自動設定）
- `DATABASE_URL`: postgresql://postgres:postgres@postgres:5432/dev_db
- `REDIS_URL`: redis://redis:6379
- `ELASTICSEARCH_URL`: http://elasticsearch:9200

## コマンド一覧

### メインコマンド（推奨）
```bash
# セットアップ・環境管理
./dev.sh setup             # 初期セットアップ
./dev.sh start              # 環境起動
./dev.sh stop               # 環境停止
./dev.sh restart            # 環境再起動
./dev.sh status             # 状態確認

# 開発作業
./dev.sh shell              # コンテナシェルに入る
./dev.sh claude             # Claude Code直接起動
./dev.sh gemini             # Gemini CLI直接起動
./dev.sh codex              # Codex CLI直接起動（未インストール時は手順案内）

# メンテナンス
./dev.sh build              # コンテナ再ビルド
./dev.sh clean              # クリーンアップ
./dev.sh logs               # ログ表示
./dev.sh test               # テスト実行
./dev.sh env                # 環境チェック
```

### Docker直接操作
```bash
# コンテナ管理
docker-compose up -d        # コンテナ起動
docker-compose down         # コンテナ停止
docker-compose exec claude-dev bash  # コンテナに入る
docker-compose logs claude-dev       # ログ確認
```

### プロジェクト管理
```bash
# 新しいプロジェクト作成後、CLAUDE.mdをコピー
cp /workspace/projects/CLAUDE.md /workspace/projects/your-project/
```

## インストール済みツール (v1.5.0)

### 開発言語・ランタイム
- Node.js 20, npm, yarn, pnpm
- Python 3, pip, venv
- Go, Java (JDK), Maven
- Rust, Cargo
- TypeScript, ts-node

### データベース・ツール
- PostgreSQL client
- Redis tools
- Elasticsearch (via docker)

### 開発ツール
- Git, Docker, Docker Compose
- Chromium browser (Playwright対応)
- nginx, netcat, curl, wget
- zsh + Oh My Zsh, fzf
- vim, nano, tmux, screen

### フロントエンド・ツール
- Create React App
- Angular CLI
- Vue CLI
- Vite, Webpack
- Jest, Mocha, ESLint, Prettier

## テスト

### クイック検証（Docker不要）
```bash
./quick-test.sh
```

### ローカル設定検証（Docker不要）
```bash
./test-local.sh
```

### フル環境テスト（Docker必須）
```bash
./test.sh
```

**注意**: フルテストにはDocker Composeと適切な権限が必要です。Docker環境がない場合は`test-local.sh`を使用してください。

### セットアップスクリプト
```bash
# メイン管理スクリプト経由（推奨）
./dev.sh setup          # セットアップ
./dev.sh test           # テスト実行

# スクリプト直接実行
./scripts/setup.sh              # Linux/macOS用（フル）
./scripts/setup-minimal.sh      # 最小セットアップ

# Windows用（PowerShell管理者権限で実行）
.\scripts\setup-windows.ps1
```

## 注意事項

- API キーは `.env` ファイルに設定し、バージョン管理には含めないでください
- `projects/` ディレクトリ内のファイルはホストマシンと同期されます
- コンテナを削除してもプロジェクトファイルは保持されます
- SSH キーはホストから読み取り専用でマウントされます

## 認証とクレデンシャル

- Claude: `~/.claude` をホストから `./claude-config` へ自動同期してマウント
- Gemini: `~/.config/gcloud` をReadOnlyマウント、`~/.gemini` をコンテナの`/home/developer/.gemini`へコピー
- OpenAI/Codex: `~/.config/openai` をReadOnlyマウント、`~/.codex` を `./codex-config` へ同期
- `.env` の `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GOOGLE_CLOUD_PROJECT` は任意（ホスト側の認証を優先）
- これらは `./dev.sh start` で自動処理。以降のコンテナ内ログイン操作は不要

## Codex CLI について

- `OPENAI_API_KEY` を `.env` に設定してください。
- 初回はコンテナ内でCodex CLIのインストールが必要です。詳細は `AGENTS.md` を参照してください。
- 設定は `codex-config/` を `/home/developer/.codex` にマウントして提供します。

### Docker権限設定

Docker-in-Docker機能を使用する場合、以下の設定が必要です：

1. **ホストのdockerグループIDを確認**:
   ```bash
   getent group docker | cut -d: -f3
   ```

2. **`.env`ファイルでDOCKER_GIDを設定**:
   ```bash
   # 例: ホストのdockerグループIDが999の場合
   echo "DOCKER_GID=999" >> .env
   ```

3. **権限問題が発生した場合**:
   - コンテナを再起動: `./dev.sh restart`
   - ホストでDockerソケットの権限を確認: `ls -l /var/run/docker.sock`
