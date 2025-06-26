# Google Gemini CLI (`google-gemini/gemini-cli`) 完全ガイド

## 1. 概要

このドキュメントは、Googleが提供する公式のNode.js製CLIツール `gemini-cli` (`github.com/google-gemini/gemini-cli`) のための包括的なガイドです。このツールは、ターミナルから直接Geminiモデルと対話し、コードの生成や編集、ファイル操作、質問応答など、多岐にわたるタスクを実行するために設計されています。

## 2. インストールと初期設定

### 2.1. 前提条件

- **Node.js**: バージョン 18 以上がインストールされている必要があります。

### 2.2. インストール

以下のコマンドを実行して、`gemini-cli`をグローバルにインストールします。

```bash
npm install -g @google/gemini-cli
```

インストール後、`gemini`コマンドが利用可能になります。

### 2.3. 認証

`gemini-cli`の認証には、主に2つの方法があります。

#### 方法1: Googleアカウントでのサインイン（推奨）

初めて`gemini`コマンドを実行すると、ブラウザが開き、Googleアカウントへのサインインを求められます。認証が完了すると、資格情報がローカルに保存されます。

- **利点**: 
    - セットアップが最も簡単です。
    - Gemini 2.5 Proを利用した無料利用枠が提供されます（分間60リクエスト、1日1,000リクエストまで）。

#### 方法2: APIキーの使用

より高いリクエスト上限が必要な場合や、特定のモデルを利用したい場合は、APIキーを使用します。

1. **APIキーの生成**: [Google AI Studio](https://ai.google.dev/)にアクセスし、APIキーを生成します。
2. **環境変数の設定**: 生成したAPIキーを`GEMINI_API_KEY`という名前の環境変数に設定します。

   ```bash
   export GEMINI_API_KEY="YOUR_API_KEY"
   ```

   この設定を永続化するには、`.bashrc`や`.zshrc`などのシェル設定ファイルに追記してください。

## 3. 基本的な使い方と主な機能

`gemini-cli`は、カレントディレクトリのコンテキストを理解し、対話的にタスクを実行します。

### 3.1. 対話モードの開始

ターミナルで`gemini`と入力するだけで、対話モードが開始します。

```bash
gemini
> (ここにプロンプトを入力)
```

### 3.2. 主なユースケース

- **アプリケーションの新規作成**: 
  空のディレクトリで`gemini`を起動し、作成したいアプリケーションの概要をプロンプトとして与えます。
  ```bash
  mkdir my-discord-bot && cd my-discord-bot
  gemini
  > Write me a Gemini Discord bot that answers questions using a FAQ.md file I will provide.
  ```

- **既存コードの理解と編集**: 
  既存のプロジェクトディレクトリで`gemini`を起動し、コードに関する質問や、機能追加・リファクタリングの指示を出します。
  ```bash
  cd existing-project/
  gemini
  > Explain what this function does. / refactor this file to be more readable.
  ```

- **一般的な質問応答**: 
  Google検索の結果をコンテキストとして利用し、最新の情報に基づいた回答を生成できます。

- **タスクの自動化**: 
  スクリプトに組み込んで、非対話的なワークフローを自動化することも可能です。

## 4. 高度な機能とカスタマイズ

### 4.1. `gemini.md`: プロジェクト固有のコンテキスト設定

`gemini-cli`の強力な機能の一つが、`gemini.md`ファイルによるカスタマイズです。プロジェクトのルートディレクトリにこのファイルを配置することで、`gemini`コマンド実行時に自動で読み込まれ、AIに永続的な指示を与えることができます。

- **目的**: 
    - **AIの振る舞いを定義**: AIのペルソナ（例: 「あなたは熟練のソフトウェアエンジニアです」）や、応答スタイルを指定します。
    - **技術スタックの明示**: プロジェクトで使用しているプログラミング言語、フレームワーク、ライブラリなどを伝えます。
    - **出力形式の指定**: コードのフォーマットや、特定のファイル形式での出力を指示します。
    - **長期的なコンテキストの提供**: プロンプトごとに入力する必要のある情報を、このファイルにまとめて記述しておくことができます。

- **自動保存**: `gemini-cli`は、対話の中で永続化すべきだと判断した情報を、自動で`gemini.md`に追記することがあります。

### 4.2. ツールの拡張性: Model Context Protocol (MCP)

`gemini-cli`は、**Model Context Protocol (MCP)** という標準規格を通じて、その機能を拡張できるように設計されています。これにより、サードパーティ製のツールや自作のツールを`gemini-cli`に統合できます。

- **仕組み**: `gemini-cli`は、MCPサーバーとして動作する外部アプリケーションに接続し、そのサーバーが提供する「ツール」を対話の中で利用することができます。
- **ユースケース**: 
    - **独自の社内ツール連携**: 社内のAPIやデータベースにアクセスするカスタムツールを作成し、`gemini-cli`から呼び出す。
    - **専門的なタスクの実行**: 特定の分野（例: 科学技術計算、金融データ分析）に特化したツールを連携させる。
    - **ワークフローの自動化**: 複数のツールを組み合わせた複雑なワークフローを定義し、`gemini-cli`から一括で実行する。

### 4.3. 実践的な`gemini.md`の記述例

以下に、様々なユースケースに応じた`gemini.md`の記述例を示します。

#### 例1: Webフロントエンド開発 (React + TypeScript)

```markdown
# Gemini Context

## Persona

You are an expert frontend developer specializing in React and TypeScript.

## Project Overview

This project is a web application built with React, TypeScript, and Vite. It uses Material-UI for components and Zustand for state management. The primary goal is to build a responsive and accessible user interface.

## Tech Stack

- **Language**: TypeScript
- **Framework**: React
- **Build Tool**: Vite
- **UI Library**: Material-UI (MUI)
- **State Management**: Zustand
- **Testing**: Jest, React Testing Library

## Coding Style

- Use functional components with Hooks.
- Prefer TypeScript for all new code.
- Follow the Airbnb JavaScript Style Guide.
- All code should be formatted with Prettier.

## Preferred Commands

- To run the development server: `npm run dev`
- To run tests: `npm test`
```

#### 例2: Pythonバックエンド開発 (FastAPI)

```markdown
# Gemini Context

## Persona

You are a backend engineer with deep expertise in Python and FastAPI.

## Project Overview

This is a high-performance REST API for a mobile application. It uses FastAPI for the web framework, Pydantic for data validation, and SQLAlchemy for database interaction with a PostgreSQL database.

## Tech Stack

- **Language**: Python 3.11+
- **Framework**: FastAPI
- **Data Validation**: Pydantic
- **ORM**: SQLAlchemy (Async)
- **Database**: PostgreSQL

## Coding Style

- Follow PEP 8 guidelines.
- Use type hints for all function signatures.
- Write asynchronous code using `async/await`.
- All endpoints must have OpenAPI documentation (docstrings).

## Instructions

- When adding new dependencies, use `poetry add`.
- Ensure all new endpoints are covered by unit tests using `pytest`.
```

## 5. コマンドラインオプションと非対話モード

`gemini`コマンドは、対話モードだけでなく、スクリプトから利用するための様々なオプションを提供しています。

### 5.1. 主要なオプション

`gemini --help`で全オプションを確認できますが、特に重要なものを以下に示します。

- `-p, --prompt <string>`: プロンプトを直接指定します。これを指定すると、`gemini`は対話モードに入らず、プロンプトを処理して終了します。
- `-m, --model <string>`: 使用するGeminiモデルを指定します。（デフォルト: `gemini-2.5-pro`）
- `-s, --sandbox`: ファイルシステムの変更などを安全に行うためのサンドボックス環境で`gemini`を実行します。
- `-a, --all_files`: カレントディレクトリ配下のすべてのファイルをコンテキストとして読み込みます。
- `-y, --yolo`: `gemini`が提案するすべてのファイル変更やコマンド実行を、確認なしで自動的に承認します。**注意: このオプションは意図しない変更を引き起こす可能性があるため、慎重に使用してください。**

### 5.2. 非対話モードでの実行例

これらのオプションを組み合わせることで、`gemini-cli`をシェルスクリプトやCI/CDパイプラインに組み込むことができます。

#### 例1: プロジェクト全体のエラーを修正する

```bash
gemini -p "Fix any type errors in the project" -a -y
```

このコマンドは、プロジェクト内の全ファイルをコンテキストとして読み込み、「プロジェクトの型エラーを修正して」というプロンプトを実行し、すべての提案を自動で承認します。

#### 例2: パイプで標準入力を渡す

`cat`や`echo`コマンドの結果をパイプで`gemini`に渡すことも可能です。

```bash
cat src/main.ts | gemini -p "Explain what this code does."
```

この例では、`src/main.ts`の内容を標準入力として`gemini`に渡し、「このコードが何をするか説明して」というプロンプトで処理させています。

## 6. トラブルシューティング

### 6.1. 認証エラー

- **問題**: `Sign in with Google`のプロンプトが繰り返し表示される、またはAPIキーで401/403エラーが出る。
- **解決策**:
    1. **資格情報のクリア**: `~/.config/gcloud/application_default_credentials.json` を削除（またはリネーム）して、`gemini`を再実行し、再度サインインを試みます。
    2. **APIキーの確認**: `echo $GEMINI_API_KEY`で環境変数が正しく設定されているか確認します。キーが正しいか、Google AI Studioで再確認します。
    3. **権限の確認**: Google Workspaceアカウントを利用している場合、管理者がAPIアクセスを制限している可能性があります。管理者に確認してください。

### 6.2. インストール・実行時エラー

- **問題**: `npm install`で失敗する、または`gemini`コマンドが見つからない (`command not found`)。
- **解決策**:
    1. **Node.js/npmの確認**: `node -v`と`npm -v`でバージョンを確認します。Node.js v18以上が必要です。
    2. **グローバルパスの確認**: `npm config get prefix`で表示されるパスが、システムの`PATH`環境変数に含まれているか確認します。含まれていない場合は、`~/.bashrc`や`~/.zshrc`に`export PATH=$(npm config get prefix)/bin:$PATH`を追記します。
    3. **プロキシ設定**: プロキシ環境下では、npmのプロキシ設定が必要です。
       ```bash
       npm config set proxy http://your-proxy-url:port
       npm config set https-proxy http://your-proxy-url:port
       ```

### 6.3. 予期せぬ動作

- **問題**: プロンプトの指示に従わない、同じ応答を繰り返す、ツール（ファイル操作など）の呼び出しに失敗する。
- **解決策**:
    1. **デバッグモードの利用**: `gemini -d` または `DEBUG=true gemini` として実行し、詳細なログを確認します。リクエストやレスポンスの内容に問題がないか調査します。
    2. **コンテキストの確認**: `gemini.md`の内容が意図通りか確認します。複雑すぎる指示や、矛盾した指示が含まれていると、AIが混乱する原因になります。
    3. **ツールのリセット**: 対話履歴がおかしくなった場合は、一度`gemini`を終了して再起動することで、セッションがリセットされます。
    4. **バグ報告**: `gemini-cli`自体のバグである可能性も考えられます。公式の[GitHubリポジトリ](https://github.com/google-gemini/gemini-cli)でIssueを検索し、なければ新規に報告します。
