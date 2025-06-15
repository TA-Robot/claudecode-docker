# Claude Code Configuration

This is a default configuration file for Claude Code in Docker environment.

## 🚨 超重要: 作業後は必ずDEVELOPMENT_STATUS.mdを更新せよ！ 🚨

**開発作業をしたら、その場で即座にDEVELOPMENT_STATUS.mdに記録すること！**

## Project Information
- **Project Type**: AI-Powered Project Management Platform
- **Technology Stack**: Node.js, TypeScript, PostgreSQL, Redis
- **Framework**: Next.js 14, Express, GraphQL, MCP (Model Context Protocol)
- **Project Name**: AI自律プロジェクト管理システム
- **Description**: Claude Codeエージェントを階層的に組織化し、AIが自律的にソフトウェアプロジェクトを推進する次世代プロジェクト管理システム
- **Agent Implementation Options**: 
  - Self-Hosted (自前AI): Anthropic APIを使用
  - Claude Code: Claude Code CLIを使用
  - Hybrid: タスクに応じて自動選択

## Development Commands

### Build Commands
```bash
# フロントエンド（Next.js）
cd frontend && npm run build

# バックエンド（Node.js）
cd backend && npm run build

# MCPサーバー
cd mcp-server && npm run build
```

### Test Commands
```bash
# 単体テスト
npm run test:unit

# 統合テスト
npm run test:integration

# E2Eテスト
npm run test:e2e

# 全テスト実行
npm test

# ログ付きテスト実行（推奨）
./scripts/run-tests-with-logs.sh
npm run test:with-logs
npm run test:unit:with-logs
npm run test:integration:with-logs
```

#### 🔍 重要: テストログの確認と修正対応 🔍

**テスト実行後は必ず以下を確認すること：**

1. **テストログの確認**
   - `logs/` ディレクトリ内の最新のテスト結果を確認
   - 特に失敗したテストがある場合は詳細を分析
   - HTMLレポート（`logs/test-report.html`）で視覚的に確認

2. **型エラーの修正優先度**
   - 現在判明している型エラー：
     - `AgentCapability` 型のエクスポート不足
     - `AgentStatus`、`TaskType` 等のenum値の不一致
     - `MCPRequest` 型定義の問題（jsonrpcプロパティ）
   - これらは優先的に修正すること

3. **修正手順**
   ```bash
   # 1. テストログを確認
   cat logs/*-test-results-*.json | jq '.testResults[] | select(.status == "failed")'
   
   # 2. 型エラーを修正
   # shared/src/types/ 内の型定義を更新
   
   # 3. テストを再実行
   ./scripts/run-tests-with-logs.sh
   
   # 4. 修正内容をDEVELOPMENT_STATUS.mdに記録
   ```

### Linting Commands
```bash
# ESLint実行
npm run lint

# 自動修正付き
npm run lint:fix

# TypeScriptの型チェックも含む
npm run lint:all
```

### Type Checking Commands
```bash
# TypeScriptコンパイルチェック
npm run typecheck

# 厳密モードでチェック
npm run typecheck:strict
```

### 開発サーバー起動
```bash
# 全サービス起動（Docker Compose）
docker-compose up

# 個別起動
npm run dev:frontend  # localhost:3000
npm run dev:backend   # localhost:4000
npm run dev:mcp       # localhost:5000
```

## Development Guidelines

### 📋 必須開発ルール

#### 1. 開発履歴管理 (MANDATORY) 🚨🚨🚨

##### ⚠️ 超重要: DEVELOPMENT_STATUS.mdの更新を絶対に忘れるな！！！ ⚠️

**開発作業を行ったら、必ず以下を実行すること：**

1. **作業開始前**: DEVELOPMENT_STATUS.mdを確認
2. **作業中**: 何を実装したかメモを取る
3. **作業完了後**: 即座にDEVELOPMENT_STATUS.mdを更新

**記録すべき内容：**
- **開発状況の記録**: 全ての機能追加・バグ修正・変更を詳細に記録
- **履歴の更新**: 作業完了時に必ずDEVELOPMENT_STATUS.mdまたは類似ファイルを更新
- **変更ログ**: 何を、なぜ、どのように変更したかを明記
- **タスク管理**: TodoやIssueでタスクを管理し、完了時にクローズ
- **進捗率の更新**: 実装フェーズの進捗率を更新
- **実装状況のチェックリスト**: 完了した項目に✅を付ける

**忘れた場合の罰則**: 次回のClaude起動時に怒られます！😠

#### 2. テスト駆動開発 (TDD) (MANDATORY)
- **Red-Green-Refactor サイクル**:
  1. **Red**: 失敗するテストを先に書く
  2. **Green**: テストを通す最小限のコードを書く
  3. **Refactor**: コードをリファクタリング
- **テストファースト**: 実装前に必ずテストを書く
- **継続的テスト**: 全てのテストが常にパスする状態を維持
- **カバレッジ**: 新機能は必ず80%以上のテストカバレッジを確保

### Code Style
- Follow existing code patterns and conventions
- Use TypeScript where applicable
- Maintain consistent formatting

### Testing (詳細)
- Write unit tests for new features (TDD mandatory)
- Write integration tests for complex features
- Ensure all tests pass before committing
- Aim for 80%+ test coverage
- Use descriptive test names and clear assertions

### Deployment
詳細は **DEPLOYMENT_STRATEGY.md** を参照してください。

#### クイックデプロイ
```bash
# ステージング環境へのデプロイ
./scripts/deploy.sh staging

# 本番環境へのデプロイ（承認必要）
./scripts/deploy.sh production
```

## Environment Setup

### Required Environment Variables
```env
# 基本設定
NODE_ENV=development
PORT=4000

# API設定
API_URL=http://localhost:4000
FRONTEND_URL=http://localhost:3000
MCP_SERVER_URL=http://localhost:5000

# データベース
DATABASE_URL=postgresql://user:password@localhost:5432/aipm_dev
REDIS_URL=redis://localhost:6379

# 認証
JWT_SECRET=your-secret-key-here
SESSION_SECRET=your-session-secret

# MCP設定
MCP_API_KEY=your-mcp-api-key
AGENT_MAX_CONCURRENT=10

# 外部サービス（オプション）
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
OPENAI_API_KEY=your-openai-key
```

### ディレクトリ構造
```
/workspace/projects/
├── frontend/          # Next.js フロントエンド
├── backend/           # Node.js APIサーバー
├── mcp-server/        # MCPサーバー実装
├── agents/            # エージェント実装
├── shared/            # 共有型定義・ユーティリティ
├── docker/            # Docker設定
├── scripts/           # ビルド・デプロイスクリプト
└── docs/              # 追加ドキュメント
```

## 開発状況履歴

### プロジェクト開始時のチェックリスト
- [x] プロジェクト情報を上記に記入
- [x] 技術スタック・フレームワークを明記
- [ ] 初期テスト環境をセットアップ
- [x] DEVELOPMENT_STATUS.mdまたは履歴ファイルを作成
- [ ] 最初のテスト（Hello World等）をTDDで実装

### 変更履歴テンプレート

#### 🔴 作業完了後、必ずDEVELOPMENT_STATUS.mdに以下を記載！ 🔴

```
#### [日付] - [変更種別]: [変更内容の概要]
- **実装内容**: [何をやったか]
- **理由**: [なぜやったか]
- **テスト**: [どのようなテストを追加/更新したか]
- **影響範囲**: [他への影響]
- **次のステップ**: [次にやることがあれば]
```

**⚠️ 記載忘れ防止チェック ⚠️**
- [ ] 実装内容は具体的に書いたか？
- [ ] ファイル名やモジュール名を含めたか？
- [ ] テストの追加/更新を記録したか？
- [ ] 進捗率を更新したか？
- [ ] チェックリストを更新したか？

### 記録例
```
#### 2025-01-06 - 機能追加: ユーザー認証機能
- **実装内容**: JWT認証とログイン/ログアウト機能を追加
- **理由**: セキュアなAPI アクセスのため
- **テスト**: auth.test.js に15個のテストケースを追加（TDD）
- **影響範囲**: APIルーター、ミドルウェア
- **次のステップ**: パスワードリセット機能の実装
```

## Project Documentation

### 概要ドキュメント
- **PROJECT_SUMMARY.md** - プロジェクト全体の概要とドキュメント一覧
- **AI_PROJECT_MANAGEMENT_DESIGN.md** - システム全体のアーキテクチャ設計
- **PM_AGENT_INFORMATION_MODEL.md** - PMエージェントが参照する情報モデル

### 仕様書
- **MCP_SERVER_API_SPEC.md** - MCPサーバーのAPI仕様
- **AGENT_COMMUNICATION_PROTOCOL.md** - エージェント間通信プロトコル
- **ERROR_HANDLING_SPEC.md** - エラーハンドリングと障害回復
- **SECURITY_SPEC.md** - セキュリティとアクセス制御
- **DATABASE_DESIGN.md** - データベーススキーマ設計
- **PERFORMANCE_REQUIREMENTS.md** - パフォーマンス要件
- **DEPLOYMENT_STRATEGY.md** - デプロイメント戦略
- **MONITORING_LOGGING_SPEC.md** - 監視とロギング
- **USER_AUTH_SPEC.md** - ユーザー認証と権限管理
- **API_SPECIFICATION.md** - REST/GraphQL API仕様

### システム構成
- **PMエージェント (Aria)**: プロジェクト全体の統括
- **開発エージェント群**: コーディングとリファクタリング
- **QAエージェント**: テスト作成と品質保証
- **DevOpsエージェント**: デプロイメントと環境管理
- **プロジェクト管理UI**: Webダッシュボード
- **MCPサーバー**: エージェント管理とタスク調整

### 開発状況
- **DEVELOPMENT_STATUS.md** - 開発履歴と進捗状況の記録

## Additional Notes
- This project is developed in a Docker container
- Source code is mounted from the host system
- Make sure to install dependencies within the container
- **重要**: 開発履歴とTDDは必須ルールです。Claude Codeがこれらのルールを遵守することを確認してください

## 🚨🚨🚨 最重要リマインダー 🚨🚨🚨

### DEVELOPMENT_STATUS.mdの更新を忘れるな！

**毎回の作業後に必ず実行すること：**
1. DEVELOPMENT_STATUS.mdを開く
2. 本日の作業内容を「変更履歴」セクションに追加
3. 「メトリクス」セクションの進捗率を更新
4. 「実装状況」のチェックリストを更新
5. 保存して、gitにコミット（する場合）

**これを忘れると：**
- プロジェクトの進捗が不明になる
- 次回の作業で混乱する
- 開発の履歴が失われる
- Claude が悲しむ 😢

### 今すぐ確認！
- [ ] DEVELOPMENT_STATUS.mdは最新か？
- [ ] 今日の作業は記録したか？
- [ ] 進捗率は正確か？
- [ ] 次のステップは明確か？
- [ ] テストログを確認して型エラーを修正したか？

### 🧪 テスト実行時の必須確認事項 🧪

**コード変更後は必ずテストログを確認！**

1. **テスト実行方法**
   ```bash
   # ログ付きでテスト実行（必須）
   ./scripts/run-tests-with-logs.sh
   ```

2. **ログ確認方法**
   ```bash
   # 最新のテスト結果を確認
   ls -lt logs/*-test-results-*.json | head -1
   
   # 失敗したテストを抽出
   jq '.testResults[] | select(.status == "failed") | .name' logs/*-test-results-*.json
   
   # HTMLレポートを確認
   open logs/test-report.html  # macOS
   xdg-open logs/test-report.html  # Linux
   ```

3. **現在の既知の問題（要修正）**
   - ❌ `AgentCapability` 型が shared/types からエクスポートされていない
   - ❌ `AgentStatus` の enum 値（AVAILABLE, BUSY など）が不一致
   - ❌ `TaskType` の enum 値（BUG_FIX, DOCUMENTATION など）が不一致
   - ❌ `MCPRequest` に jsonrpc プロパティが定義されていない
   - ❌ 統合テストのパスパターンが正しく設定されていない

4. **修正後の確認**
   - テストが全て通ることを確認
   - カバレッジが80%以上であることを確認
   - 修正内容をDEVELOPMENT_STATUS.mdに記録

**Remember: No code without documentation! No work without history! No commit without testing!**
