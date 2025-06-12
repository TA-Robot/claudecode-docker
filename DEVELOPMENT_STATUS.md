# Claude Code Docker Environment - 開発状況

## プロジェクト概要
Docker上でClaude Codeを使用するための開発環境テンプレート。コンテナ内でClaude Codeを実行し、プロジェクトファイルはホストとマウント共有する構成。

## 現在の開発状況

### 完了済み機能

#### 1. 基本環境構築 ✅
- **Dockerfile作成**: Node.js 20 + Claude Code環境
- **docker-compose.yml**: ボリュームマウント設定付き
- **環境変数テンプレート**: `.env.example`でAPI키 설정
- **Git管理**: `.gitignore`で機密情報除外

#### 2. Claude Code設定 ✅
- **自動承認設定**: `claude-config/settings.json`
  - 44個の開発コマンドを自動承認（npm, git, python等）
  - 基本ツール（bash, edit, read等）をallow設定
  - 危険なシステムコマンドのみ確認要求
  - 5個の危険コマンドをブロック
- **プロジェクトテンプレート**: `projects/CLAUDE.md`

#### 3. テスト環境 ✅
- **3段階テストスクリプト**:
  - `quick-test.sh`: 基本ファイル構造チェック
  - `test-local.sh`: Docker不要の詳細設定検証
  - `test.sh`: 完全なDocker環境テスト
- **テスト結果**: ローカル検証で全項目パス

#### 4. ドキュメント ✅
- **README.md**: セットアップ・使用方法
- **詳細な手順書**: コマンド一覧、注意事項

#### 5. セットアップ自動化 ✅
- **マルチOS対応セットアップスクリプト**:
  - `setup.sh`: Linux/macOS用（Ubuntu/Debian, CentOS/RHEL/Rocky, macOS対応）
  - `setup-windows.ps1`: Windows用（WSL2 + Docker Desktop自動インストール）
  - `setup-minimal.sh`: Docker既存環境用（権限不要）
  - `install-compose.sh`: Docker Compose個別インストーラー
- **自動化機能**:
  - OS自動検出とパッケージマネージャー選択
  - Docker + Docker Compose自動インストール
  - ユーザー権限設定（dockerグループ追加）
  - 環境ファイル(.env)自動作成

#### 6. 開発体験向上 ✅
- **統合管理スクリプト**: `dev.sh`
  - 環境管理: start/stop/restart/status
  - 開発作業: shell/claude/logs
  - メンテナンス: build/clean/test/env
- **TDD・履歴管理ルール**: `projects/CLAUDE.md`に必須ルールを明記
  - テスト駆動開発（TDD）の徹底
  - 開発履歴記録の義務化
  - 変更ログテンプレート提供

#### 7. スクリプト体系化 ✅
- **scripts/ディレクトリ構造化**:
  - セットアップ関連スクリプト整理
  - テスト関連スクリプト整理
  - 各スクリプトの役割明確化
- **ドキュメント体系化**:
  - `scripts/README.md`: スクリプト詳細説明
  - メインREADME更新: クイックスタート追加
  - コマンド体系の整理と統一

## 技術仕様

### アーキテクチャ
```
Host Machine
├── claude-docker/           # プロジェクトルート
│   ├── projects/            # 開発プロジェクト（マウント）
│   ├── claude-config/       # Claude設定（マウント）
│   └── Docker環境
│
Docker Container
├── /workspace/projects/     # ホストのprojects/と同期
├── /root/.config/claude/    # Claude設定
└── Claude Code + 開発ツール
```

### 設定詳細
- **ベースイメージ**: node:20-slim
- **自動承認コマンド**: 44個
- **ブロックコマンド**: 5個（format*, rm -rf /*, 等）
- **ボリュームマウント**: 双方向同期

## 品質保証

### テスト戦略
1. **静的検証**: ファイル構造・JSON構文チェック
2. **設定検証**: Claude Code設定項目の妥当性
3. **統合テスト**: Docker環境での動作確認

### テスト結果
- ✅ 基本検証: 全項目パス
- ✅ 設定検証: 全項目パス  
- ⚠️ Docker統合テスト: 権限問題で未完了（修正済み）

## 今後の改善点

### 短期課題
- [ ] Docker環境での実際の動作確認
- [ ] より詳細なエラーハンドリング
- [ ] パフォーマンス最適化

### 長期的な拡張
- [ ] 複数言語サポート（Python, Go等）
- [ ] CI/CD統合
- [ ] セキュリティ強化

## 使用開始手順

### 初回セットアップ（v1.2.0対応）
```bash
# 1. リポジトリクローン/ダウンロード
cd claude-docker

# 2. 自動セットアップ（推奨）
./setup.sh
# または
./dev.sh setup

# 3. 環境変数設定（自動作成されます）
# .envファイルでANTHROPIC_API_KEYを設定

# 4. 即座に開発開始
./dev.sh claude
```

### 日常的な使用（v1.2.0対応）
```bash
# 統合管理スクリプトで簡単操作
./dev.sh start     # 環境起動
./dev.sh claude    # Claude Code直接起動
./dev.sh shell     # コンテナに入って作業
./dev.sh stop      # 環境停止

# 従来方式（互換性維持）
docker-compose up -d
docker-compose exec claude-dev bash
cd /workspace/projects/your-project
claude
docker-compose down
```

## 更新履歴

### v1.2.0 (2025-01-06) - 開発体験大幅改善
- **メイン管理スクリプト追加**: `dev.sh`でワンコマンド操作実現
- **スクリプト体系化**: `scripts/`ディレクトリ構造で整理
- **Docker Compose問題解決**: 個別インストーラー`install-compose.sh`追加
- **使用方法大幅簡略化**: `./dev.sh claude`で即座に開発開始可能
- **ドキュメント体系化**: クイックスタート追加、コマンド体系整理

### v1.1.0 (2025-01-06) - マルチOS対応・TDD強化  
- **マルチOS自動セットアップ**: Linux(Ubuntu/Debian/CentOS/RHEL/Rocky)/macOS/Windows対応
- **TDD・履歴管理ルール**: 必須開発ルールを`projects/CLAUDE.md`に明記
- **自動化強化**: OS検出、パッケージマネージャー選択、権限設定自動化
- **開発状況文書化**: `DEVELOPMENT_STATUS.md`で進捗・技術仕様を詳細記録

### v1.0.0 (2025-01-06) - 初期リリース
- 初期リリース
- 基本Docker環境構築
- Claude Code自動承認設定
- 3段階テストスクリプト
- 包括的ドキュメント

## 貢献ガイドライン

### 開発方針
- 設定変更時は必ずテストスクリプト実行
- 新機能追加時はドキュメント更新必須
- セキュリティ設定の変更は慎重に検討

### ファイル構成ルール
- 機密情報は`.env`のみ（バージョン管理除外）
- 設定変更は`claude-config/`内で管理
- プロジェクトファイルは`projects/`内に配置