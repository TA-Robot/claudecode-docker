# Claude Code Docker Development Environment

Docker上でClaude Codeを使用するための開発環境テンプレートです。

## 特徴

- **共通Dockerイメージ**: 複数プロジェクトで同じイメージを共有
- **プロジェクト分離**: 各ディレクトリのprojects/は独立してマウント
- **自動コンテナ識別**: ディレクトリパスのハッシュでコンテナを自動識別
- **同時起動対応**: 複数のclaudecode-dockerディレクトリを同時に使用可能

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
# .envファイルを編集してANTHROPIC_API_KEYを設定
```

### 3. 開発開始
```bash
# 環境を起動してClaude Codeを開始
./dev.sh claude

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
`.env` ファイルを編集して、Anthropic API キーを設定してください。

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
- **同時起動対応**: 複数のclaudecode-dockerディレクトリを同時に使用可能

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