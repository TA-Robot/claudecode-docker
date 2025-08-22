# Scripts Directory

このディレクトリには、Claude Code Docker環境の管理に使用するスクリプトが含まれています。

## スクリプト一覧

### セットアップ関連
- **`setup.sh`** - メインセットアップスクリプト（Linux/macOS）
- **`setup-windows.ps1`** - Windowsセットアップスクリプト（PowerShell）
- **`setup-minimal.sh`** - 最小セットアップ（Docker既存環境用）
- **`install-compose.sh`** - Docker Compose個別インストール
- **`playwright-mcp.sh`** - Playwright MCP のホスト側インストール/実行補助

### テスト関連
- **`test.sh`** - 完全なDocker環境テスト
- **`test-local.sh`** - ローカル設定検証（Docker不要）
- **`quick-test.sh`** - 基本ファイル構造チェック

## 使用方法

### 直接実行
```bash
# スクリプトディレクトリから実行
cd scripts
./setup.sh

# ルートディレクトリから実行
./scripts/setup.sh
```

### メインスクリプト経由（推奨）
```bash
# ルートディレクトリのdev.shを使用
./dev.sh setup    # セットアップ
./dev.sh test     # テスト実行

### Playwright MCP（ホスト側）
```bash
# インストール（npmグローバル）。権限が必要な場合は sudo を付与
./scripts/playwright-mcp.sh install

# 起動（引数はそのまま渡せます）
./scripts/playwright-mcp.sh run --help

# 状態確認
./scripts/playwright-mcp.sh status
```
```

## スクリプト詳細

### setup.sh
- OS自動検出（Ubuntu/Debian、CentOS/RHEL/Rocky、macOS）
- Docker + Docker Compose自動インストール
- ユーザー権限設定
- 環境ファイル作成

### setup-windows.ps1
- WSL2有効化
- Docker Desktop自動インストール
- 管理者権限チェック
- PowerShell対応

### setup-minimal.sh
- Docker既存環境用
- sudo権限不要
- 設定ファイル作成のみ

### install-compose.sh
- Docker Compose専用インストーラー
- apt-get + 手動インストール対応
- PATH設定自動化

### テストスクリプト
- **test.sh**: Docker環境での統合テスト
- **test-local.sh**: 設定ファイル検証
- **quick-test.sh**: 基本構造チェック

## トラブルシューティング

### 権限エラー
```bash
chmod +x scripts/*.sh
```

### Docker Compose問題
```bash
./scripts/install-compose.sh
```

### 設定検証
```bash
./scripts/test-local.sh
```
