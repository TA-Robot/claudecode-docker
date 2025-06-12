# Claude Code Configuration

This is a default configuration file for Claude Code in Docker environment.

## Project Information
- **Project Type**: [Web App / API / CLI / Library / etc.]
- **Technology Stack**: [Node.js, Python, Go, etc.]
- **Framework**: [React, Express, FastAPI, etc.]

## Development Commands

### Build Commands
```bash
# Add your build commands here
npm run build
# or
yarn build
```

### Test Commands
```bash
# Add your test commands here
npm test
# or
yarn test
```

### Linting Commands
```bash
# Add your linting commands here
npm run lint
# or
yarn lint
```

### Type Checking Commands
```bash
# Add your type checking commands here
npm run typecheck
# or
yarn typecheck
```

## Development Guidelines

### 📋 必須開発ルール

#### 1. 開発履歴管理 (MANDATORY)
- **開発状況の記録**: 全ての機能追加・バグ修正・変更を詳細に記録
- **履歴の更新**: 作業完了時に必ずDEVELOPMENT_STATUS.mdまたは類似ファイルを更新
- **変更ログ**: 何を、なぜ、どのように変更したかを明記
- **タスク管理**: TodoやIssueでタスクを管理し、完了時にクローズ

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
- [Add deployment instructions here]

## Environment Setup

### Required Environment Variables
```
NODE_ENV=development
API_URL=http://localhost:3000
```

## 開発状況履歴

### プロジェクト開始時のチェックリスト
- [ ] プロジェクト情報を上記に記入
- [ ] 技術スタック・フレームワークを明記
- [ ] 初期テスト環境をセットアップ
- [ ] DEVELOPMENT_STATUS.mdまたは履歴ファイルを作成
- [ ] 最初のテスト（Hello World等）をTDDで実装

### 変更履歴テンプレート
```
#### [日付] - [変更種別]: [変更内容の概要]
- **実装内容**: [何をやったか]
- **理由**: [なぜやったか]
- **テスト**: [どのようなテストを追加/更新したか]
- **影響範囲**: [他への影響]
- **次のステップ**: [次にやることがあれば]
```

### 記録例
```
#### 2025-01-06 - 機能追加: ユーザー認証機能
- **実装内容**: JWT認証とログイン/ログアウト機能を追加
- **理由**: セキュアなAPI アクセスのため
- **テスト**: auth.test.js に15個のテストケースを追加（TDD）
- **影響範囲**: APIルーター、ミドルウェア
- **次のステップ**: パスワードリセット機能の実装
```

## Additional Notes
- This project is developed in a Docker container
- Source code is mounted from the host system
- Make sure to install dependencies within the container
- **重要**: 開発履歴とTDDは必須ルールです。Claude Codeがこれらのルールを遵守することを確認してください