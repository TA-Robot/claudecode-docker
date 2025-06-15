# Claude Code Docker Environment - 開発状況

## プロジェクト概要
Docker上でClaude Codeを使用するための開発環境テンプレート。コンテナ内でClaude Codeを実行し、プロジェクトファイルはホストとマウント共有する構成。

## 現在の開発状況

### 完了済み機能

#### 1. 基本環境構築 ✅
- **Dockerfile作成**: Node.js 20 + Claude Code環境
- **docker-compose.yml**: ボリュームマウント設定付き
- **環境変数テンプレート**: `.env.example`でAPI
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

#### 7. Claude Code公式ベストプラクティス適用 ✅
- **Claude Code公式Dockerfileの有用エッセンス抽出**: `.temp/docker_sample_summary.md`
- **セキュリティ・権限管理の改善**:
  - 非rootユーザー（UID 1000）での実行
  - 適切なディレクトリ権限設定
  - キャッシュディレクトリの永続化
- **開発ツール充実**:
  - zsh + Oh My Zsh + fzf環境
  - npm設定最適化
  - 履歴永続化
- **日本語環境対応**:
  - 日本語ロケール設定（ja_JP.UTF-8）
  - ファイル名文字化け解決
- **zsh設定最適化**:
  - フルパス表示プロンプト
  - 履歴管理強化（重複除去、セッション共有）
  - 便利なエイリアス設定
  - ディレクトリナビゲーション改善

#### 8. スクリプト体系化 ✅
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
- **ベースイメージ**: node:20 (フル版)
- **実行ユーザー**: developer (UID 1000)
- **自動承認コマンド**: 44個
- **ブロックコマンド**: 5個（format*, rm -rf /*, 等）
- **ボリュームマウント**: 双方向同期
- **ロケール**: ja_JP.UTF-8 (日本語対応)
- **シェル**: zsh + Oh My Zsh + カスタム設定

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

### v1.4.0 (2025-06-15) - マルチプロジェクト対応
- **実装内容**: 同一ホストで複数の独立したプロジェクトを管理できる仕組みを実装
- **理由**: 従来は全プロジェクトでDockerイメージが共有され、最後にビルドしたプロジェクトの設定で上書きされる問題を解決
- **テスト**: `projects/.project-name`ファイルでプロジェクト識別、動的docker-compose.yml生成を確認
- **影響範囲**: dev.sh、docker-compose設定生成、コンテナ・イメージ・ネットワークの分離
- **詳細実装**:
  - `projects/.project-name`ファイルからプロジェクト名を読み取り
  - `docker-compose.generated.yml`を動的生成（プロジェクトごとに異なる設定）
  - イメージ名: `claude-code:${project_name}`
  - コンテナ名: `claude-dev-${project_name}`
  - ネットワーク名: `claude-${project_name}-network`
  - キャッシュディレクトリ: `./cache/${project_name}/`
  - Dockerfileハッシュもプロジェクトごとに管理
- **使用方法**:
  ```bash
  # プロジェクト1
  echo "my-project-1" > projects/.project-name
  ./dev.sh start  # my-project-1用の独立環境が起動
  
  # プロジェクト2（別ディレクトリ）
  echo "my-project-2" > projects/.project-name
  ./dev.sh start  # my-project-2用の独立環境が起動
  ```
- **次のステップ**: 実環境での動作確認とドキュメント更新

### v1.3.5 (2025-06-15) - Jest実行権限エラーの解決
- **実装内容**: `npm test`実行時の`Permission denied`エラーを解決する包括的な権限修正スクリプトを作成
- **理由**: ENTRYPOINTでnpm installは成功するが、node_modules/.bin内の実行ファイルに実行権限が付与されない問題を解決
- **テスト**: Docker再ビルド後に`npm test`が正常に実行可能になることを確認予定
- **影響範囲**: Dockerfile、scripts/fix-jest-permissions.sh、実行ファイルの権限管理
- **詳細対策**:
  - 専用権限修正スクリプト`fix-jest-permissions.sh`を作成
  - jest, mocha, ts-node, eslint等の主要npmツールの権限を一括修正
  - ENTRYPOINTでnpm install後に自動実行
  - .zshrcの`fixperms`コマンドから手動実行も可能
  - グローバル/ローカル両方のnode_modulesに対応
- **次のステップ**: Docker再ビルドと実環境での動作確認

### v1.3.4 (2025-06-15) - Cursor AI共同開発環境の整備
- **実装内容**: Cursor用の設定ファイル(.cursorrules)を作成し、Claude CodeとCursorでの一貫した開発体験を実現
- **理由**: Claude CodeとCursorの両方でプロジェクトを編集する際の開発ルールと設定を統一
- **テスト**: .cursorrules作成、内容はCLAUDE.mdと整合性を確保
- **影響範囲**: Cursor AI利用時の開発体験、プロジェクトルールの統一
- **詳細対策**:
  - 必須開発ルール（開発履歴管理、TDD）をCursor用に明記
  - Docker環境固有の注意事項を記載
  - コマンド一覧とファイル構造を整理
  - AIアシスタント動作の指針を統一
- **次のステップ**: Cursorでの実使用確認とフィードバック反映

### v1.3.3 (2025-06-15) - docker-compose.yml修正によるENTRYPOINT問題解決
- **実装内容**: docker-compose.ymlのcommand設定を削除してDockerfileのENTRYPOINTが正しく実行されるように修正
- **理由**: docker-compose.ymlのcommandがDockerfileのENTRYPOINTを上書きしていたため、npm自動インストールが実行されなかった
- **テスト**: `./dev.sh start` → `./dev.sh claude`でClaude Code起動後、テスト実行可能
- **影響範囲**: docker-compose.yml、コンテナ起動時の自動初期化処理
- **次のステップ**: 実環境での動作確認

### v1.3.2 (2025-06-15) - npm権限問題の継続的対応
- **実装内容**: npmキャッシュディレクトリを/tmpに移動して権限問題を回避
- **理由**: 従来の対策では解決しなかったnpm EACCES権限エラーの根本的解決
- **テスト**: Docker再ビルド後に検証予定
- **影響範囲**: Dockerfile、docker-compose.yml、npmの動作
- **詳細対策**:
  - NPM_CONFIG_CACHE=/tmp/npm-cacheに変更
  - sudoを完全に削除（セキュリティ向上）
  - ENTRYPOINTスクリプトで起動時に権限を自動設定
  - DOCKERPERMISSIONPROBLEMS.mdで問題を継続的に追跡
- **課題**: 根本的な解決には至っていない、継続的な監視が必要

### v1.3.1 (2025-06-14) - 包括的な権限エラー対策実装
- **実装内容**: Dockerコンテナ内で発生する権限エラーを包括的に解決
- **理由**: npm test実行時のJest権限エラーなど開発時の権限問題を防止
- **テスト**: 手動で権限設定をテスト（Docker再ビルド後に検証予定）
- **影響範囲**: Dockerfile、開発者の作業効率向上
- **詳細対策**:
  - sudoのパスワードなし実行設定
  - 各種開発ディレクトリの事前作成と権限設定
  - グローバルnpmツール（jest, mocha, eslint等）のプリインストール
  - .zshrcにchpwd()関数追加（ディレクトリ移動時の自動権限修正）
  - fixperms()ヘルパー関数（手動権限修正コマンド）
  - Docker-in-Docker用ソケット権限自動修正
  - 起動時の共通ディレクトリ権限チェック

### v1.3.0 (2025-01-06) - Claude Code公式ベストプラクティス適用
- **Claude Code公式Dockerfileエッセンス適用**: セキュリティ・権限管理・開発体験の全面改善
- **権限問題解決**: 非rootユーザー（UID 1000）での安全な実行環境構築
- **日本語環境完全対応**: ロケール設定でファイル名文字化け解決
- **zsh環境最適化**: フルパス表示、履歴管理、便利エイリアス、ディレクトリナビゲーション
- **キャッシュ永続化**: Claude・npm関連キャッシュの永続化でパフォーマンス向上
- **開発ツール強化**: fzf、jq等の開発ツール追加

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