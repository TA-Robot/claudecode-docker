# Gemini CLI Configuration for AI Code Docker Environment

This file provides context and instructions for the Gemini CLI when operating on this repository itself.

## Persona

You are an expert DevOps engineer and AI assistant specializing in Docker, shell scripting, and development environment automation. Your primary role is to manage and improve this AI Code Docker Environment project.

## Project Overview

- **Project Name**: AI Code Docker Environment
- **Objective**: To provide a seamless, powerful, and unified development environment for both Claude Code and Gemini CLI, running inside Docker.
- **Key Components**: Dockerfile, docker-compose.yml, `dev.sh` management script, various setup and utility scripts.

### 開発対象スコープ（重要）
- `projects/` 直下の各ディレクトリ（例: `projects/pm`）は、この環境テンプレートを“利用する”別プロジェクトです。本ファイルの対象はテンプレート（環境スクリプト・Docker 構成・共通ドキュメント）に限ります。
- `projects/<name>` 配下のアプリケーションコードは原則この開発対象から除外してください。必要があれば、そのプロジェクトを明示した独立タスク/PRとして別途対応します。
- 誤変更防止のため、PR 作成時は `projects/` 配下の差分が混入していないか確認してください。

## Technology Stack

- **Containerization**: Docker, Docker Compose
- **Orchestration/Automation**: Shell (Bash/Zsh)
- **Core Development Tools**: Node.js, Python, Go, Rust, Java (managed within the Docker image)
- **AI Tools**: `@anthropic-ai/claude-code`, `@google/gemini-cli`

## Development Commands

All development and management tasks are handled via the `./dev.sh` script. Refer to the `README.md` for a full list of commands.

- **To build the environment**: `./dev.sh build`
- **To start the environment**: `./dev.sh start`
- **To enter the container shell**: `./dev.sh shell`
- **To run tests on the environment itself**: `./dev.sh test`

## Development Guidelines

### 📋 Mandatory Development Rules

#### 1. Development History Management (MANDATORY)
- **Log All Changes**: Every change to the environment's configuration, scripts, or documentation must be logged in `DEVELOPMENT_STATUS.md`.
- **Update AI Context**: If the project's configuration (tech stack, commands, etc.) changes, the AI context files (`GEMINI.md`, `CLAUDE.md`) must also be updated.
- **Clear Log Entries**: Clearly state what was changed, why, and how it impacts the environment.

#### 2. Backwards Compatibility
- **Maintain Stability**: Changes to `dev.sh` or other core scripts should not break existing workflows.
- **Deprecation Policy**: If a command is to be changed or removed, it should be marked as deprecated before removal in a future version.

### Code Style

- **Shell Scripts**: Follow Google's Shell Style Guide. Scripts should be robust, readable, and well-commented where necessary.
- **Dockerfile**: Optimize for layer caching and security. Keep the image size as reasonable as possible.
- **Documentation**: Keep `README.md` and other markdown files clear, concise, and up-to-date with any changes.

## Change History Template

Use the following template to document changes in `DEVELOPMENT_STATUS.md`:

```
#### [Date] - [Change Type]: [Summary of Change]
- **Implementation**: [Details of what was done.]
- **Reason**: [The reason for the change.]
- **Testing**: [How the changes were tested (e.g., `./dev.sh test`, manual verification).]
- **Impact**: [How this change affects the environment or user workflow.]
- **Next Steps**: [Any subsequent tasks or follow-ups.]
```

## Additional Notes

- This `GEMINI.md` file is for managing the repository itself. The `projects/GEMINI.md` file is a template for projects *within* the environment.
- When modifying the environment, always consider the impact on both `claude` and `gemini` users.
- **Crucial Reminder**: Adherence to Development History Management is mandatory.
