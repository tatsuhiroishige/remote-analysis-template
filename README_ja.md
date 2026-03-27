# Claude Code リモート解析フレームワーク

[Claude Code](https://claude.ai/code) をAIリモートオペレータとして使い、リモート計算サーバー上でROOTベースの物理解析を実行するフレームワーク。

## 概要

このシステムは、Claude Codeとの自然言語での会話を通じて、リモートサーバー上の粒子物理学解析を制御します。Claude はMCP（Model Context Protocol）サーバーを介してリモートサーバーを操作し、nvimでのファイル編集、マクロ実行、出力監視をSSH + tmux経由で完全な可視性を持って行います。

**基本コンセプト**: Claude Codeは*リモートオペレータ*として機能します。ソースコード、データ、計算はすべてリモートサーバー上にあり、このローカルリポジトリにはコントローラ（MCPサーバー、スクリプト、ルール、ドキュメント）のみが含まれます。

## アーキテクチャ

```
ローカルマシン                               リモートサーバー
┌────────────────────────────┐            ┌────────────────────────────┐
│  Claude Code CLI           │            │  tmux session "claude"     │
│    │                       │            │    │                       │
│    └─ MCP Server           │            │    ├─ nvim（ファイル編集） │
│       (remote_mcp_server.py)│           │    └─ terminal（コマンド） │
│       │                    │            │                            │
│       ├─ Layer 1 ──────────┼──(tmux)──► │  （メインペイン、~0ms）   │
│       └─ Layer 2 ──────────┼──(SSH)───► │  （並列セッション、~1s）  │
│                            │            │                            │
│  tmux "remote-server"      │            │  作業ディレクトリ:          │
│    └─ pane 0: リモート     │            │  ├── macro/  (ROOTマクロ)  │
│       tmuxにSSH接続済み ───┼───────────►│  ├── param/  (JSON設定)    │
│                            │            │  ├── root/   (出力ROOT)    │
│  Rules, Skills, Agents,    │            │  ├── pic/    (出力PDF)     │
│  Hooks                     │            │  └── log/    (ログ)        │
└────────────────────────────┘            └────────────────────────────┘
```

### 2層コマンドトランスポート

MCPサーバーはリモートサーバーとの通信に**2つの異なるトランスポート層**を使用します。この2層設計により、速度と機能性を両立しています。

```
                         ┌─────────────────────────────────────────┐
                         │      Layer 1: ローカルtmuxリレー        │
  Claude Code            │           （メインペイン）              │
    │                    │                                         │
    │  run("make")       │  tmux send-keys           SSH接続済み  │
    │──────────────────► │  -t remote-server:view.0 ────────────► │ リモートシェル
    │                    │       (~0ms)              (常時接続)    │ がコマンド実行
    │                    │                                         │
    │  run_output(50)    │  tmux capture-pane                     │
    │◄────────────────── │  -t remote-server:view.0 ◄──────────── │ 画面内容取得
    │                    └─────────────────────────────────────────┘
    │
    │                    ┌─────────────────────────────────────────┐
    │                    │      Layer 2: 直接SSH                   │
    │                    │      （ファイルI/O、並列セッション）    │
    │                    │                                         │
    │  read_file(path)   │  ssh remote-server "cat <path>"        │
    │──────────────────► │       (~1.3s/回)                        │
    │                    │                                         │
    │  term_send(s, cmd) │  ssh remote-server                     │
    │──────────────────► │    "tmux send-keys -t <s> ..."         │
    │                    └─────────────────────────────────────────┘
```

**Layer 1 — ローカルtmuxリレー**（メインペインのコマンド: `run`, `run_output`, nvim編集）
- ローカルtmuxペイン（`remote-server:view.0`）がリモートtmuxセッションへの持続的SSH接続を維持
- コマンドは `tmux send-keys` でキーストロークとして送信、出力は `tmux capture-pane` でキャプチャ
- **レイテンシ ~0ms** — コマンドごとのSSHラウンドトリップなし。SSH接続は確立済み
- nvim編集やマクロ実行はこの仕組みで動作: キーストロークがローカルペイン経由でリモートターミナルに到達

**Layer 2 — 直接SSH**（ファイル読み取り、並列セッション: `read_file`, `term_send`, `term_output`）
- 構造化された出力が必要な操作に使用（ファイル内容、リモートtmuxコマンド）
- 各呼び出しで新規SSHを実行: `ssh remote-server "..."`
- **レイテンシ ~1.3s/回** だが、クリーンなプログラム的出力を返す
- SSH ControlMasterが既存接続を再利用するため、認証オーバーヘッドなし

**なぜ2層か？**
- Layer 1は高速だが、画面スクレイピング出力のみ（ターミナルに見える内容）
- Layer 2は低速だが、正確なファイル内容を返し、任意のリモートtmuxセッションを対象にできる
- nvim検出（INSERTモード、ステータスバー）はLayer 1の画面キャプチャ解析で行う — リモートクエリ不要

### コンポーネント

1. **MCPサーバー** (`scripts/remote_mcp_server.py`) が2層トランスポートを通じてnvim経由のファイル編集、コマンド実行、セッション管理のツールを提供
2. **Rules** (`.claude/rules/`) がコーディング規約、編集ワークフロー、安全ポリシー、コミュニケーションスタイルを定義
3. **Skills** (`.claude/skills/`) がスラッシュコマンド（`/analysis`, `/plotting`, `/remote-ide` など）で一般的なワークフローをガイド
4. **Agents** (`.claude/agents/`) がビルド、コード探索、データ検査、物理レビューの専門サブエージェント
5. **Hooks** (`.claude/hooks/`) が安全性の強制（危険なコマンドのブロック）、編集後の確認リマインド、コンテキスト圧縮時の処理を実行

## 前提条件

### 1. ControlMaster付きSSHアクセス

`~/.ssh/config` に追加:

```
Host remote-server
    HostName your-server.example.com
    User your-username
    IdentityFile ~/.ssh/id_rsa
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

```bash
mkdir -p ~/.ssh/sockets
ssh remote-server "echo '接続OK'"
```

### 2. リモートtmuxセッション

```bash
ssh remote-server "tmux new-session -d -s claude"
```

### 3. Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

### 4. Python依存（MCPサーバー用）

```bash
pip install mcp  # または: uv add mcp
```

### 5. リモートサーバーのROOT環境

リモートシェル設定（`.bashrc`, `.cshrc` 等）でROOTが利用可能であること:

```bash
source /path/to/root/bin/thisroot.sh
```

## クイックスタート

### 1. クローンと設定

```bash
git clone https://github.com/tatsuhiroishige/remote-analysis-template.git
cd remote-analysis-template
```

### 2. 設定を編集

サーバーの詳細を以下のファイルに記入:

| ファイル | 変更内容 |
|---------|---------|
| `.claude/CLAUDE.md` | WORKDIR、シェル種類、tmuxセッション名 |
| `scripts/remote_mcp_server.py` | `REMOTE`, `WORKDIR`, `SETUP_CMD`, `LOCAL_PANE` |
| `scripts/remote_cli.sh` | `REMOTE`, `WORKDIR`, `LOCAL_PANE` |
| `scripts/local_tmux_init.sh` | SSHエイリアス、tmuxセッション名 |

### 3. ローカルtmuxの初期化

```bash
./scripts/local_tmux_init.sh
```

### 4. Claude Codeを起動

```bash
claude
```

### 5. 作業開始

```
> デフォルトパラメータでstudyマクロを実行して
> まだ実行中か確認して
> 出力PDFを見せて
```

## ディレクトリ構成

### ローカル（このリポジトリ）

```
remote-analysis-template/
├── .claude/
│   ├── CLAUDE.md                  # メイン設定（ここを編集）
│   ├── settings.json              # MCPサーバー・Hooks設定
│   ├── rules/
│   │   ├── coding.md              # コーディング規約 (ROOT/C++)
│   │   ├── editing.md             # リモートファイル編集ワークフロー
│   │   ├── safety.md              # 許可/禁止操作
│   │   ├── communication.md       # Todoワークフロー、Discord、Notion
│   │   ├── documentation.md       # ドキュメント自動更新ポリシー
│   │   └── self-improvement.md    # ミスのレッスン追跡
│   ├── skills/
│   │   ├── analysis/SKILL.md      # /analysis — 解析ワークフロー
│   │   ├── remote-ide/SKILL.md    # /remote-ide — セッション管理
│   │   ├── plotting/SKILL.md      # /plotting — ROOT描画・QAアップロード
│   │   ├── job-submission/SKILL.md # /job-submission — バッチジョブ
│   │   ├── monte-carlo/SKILL.md   # /monte-carlo — MCシミュレーション
│   │   ├── data-reading/SKILL.md  # /data-reading — データ形式・API
│   │   ├── log-notion/SKILL.md    # /log-notion — Notionログ
│   │   └── notebooklm-research/SKILL.md
│   ├── agents/                    # 専門サブエージェント
│   └── hooks/                     # 安全性・リマインダー・通知
├── scripts/
│   ├── remote_mcp_server.py       # MCPサーバー（主インターフェース）
│   ├── remote_cli.sh              # CLIヘルパー（フォールバック）
│   ├── local_tmux_init.sh         # ローカルtmuxセットアップ
│   └── discord_bot.py             # Discordボット
├── config/                        # Webhooks等
├── docs/                          # 解析知識ベース
├── todo/                          # タスク追跡
├── output/                        # ダウンロード出力
├── QA/                            # QAプロット
└── .mcp.json                      # MCPサーバー登録
```

## MCPツールリファレンス

### ファイル編集（nvim経由）

| ツール | 説明 |
|-------|------|
| `open_file(path)` | nvimでファイルを開く |
| `replace(old, new)` | 全置換 |
| `insert_after(line, text)` | 指定行の後にテキスト挿入 |
| `bulk_insert(line, text)` | 大きなブロックを挿入 |
| `delete_lines(start, end)` | 行範囲を削除 |
| `commit_edit(path, summary)` | 保存 + diff報告 |
| `read_file(path)` | ファイル内容を読み取り |
| `write_new_file(path, content)` | 新規ファイル作成 |

### コマンド実行

| ツール | 説明 |
|-------|------|
| `run(cmd)` | コマンド実行（nvim自動終了） |
| `run_output(lines)` | ターミナル出力をキャプチャ |
| `run_busy()` | プロセス実行中か確認 |
| `run_kill()` | Ctrl+Cを送信 |

### 並列セッション

| ツール | 説明 |
|-------|------|
| `term_new(name)` | 名前付きtmuxセッション作成 |
| `term_send(name, cmd)` | セッションにコマンド送信 |
| `term_output(name, lines)` | セッション出力をキャプチャ |
| `term_close(name)` | セッションを終了 |

## カスタマイズガイド

### ステップ1: サーバー設定

`scripts/remote_mcp_server.py` を編集:

```python
REMOTE = "remote-server"           # SSHエイリアス
SESSION = "claude"                  # リモートtmuxセッション名
WORKDIR = "/home/<USER>/<PROJECT>"  # リモート作業ディレクトリ
SETUP_CMD = "source <SETUP_SCRIPT>" # 環境セットアップコマンド
LOCAL_PANE = "remote-server:view.0" # ローカルtmuxペイン
```

### ステップ2: CLAUDE.md

`.claude/CLAUDE.md` に環境情報（WORKDIR、シェル、tmux名）を記入。

### ステップ3: ドキュメント追加

作業を進めながら `docs/` を構築。推奨構造:

```
docs/
├── analysis/       # 解析手法、カット、結果
├── experiment/     # 実験の知識（検出器、PID、運動学）
├── root-api/       # ROOT/フレームワークのコーディングパターン
├── simulation/     # MC生成チェーン
├── computing/      # リモートサーバーインフラ
├── workflow/       # Notion、Discord、QA手順
└── lessons/        # ミスのログ（自己改善用）
```

### ステップ4: ルールの適応

`.claude/rules/` を確認・編集:
- `coding.md` — マクロの命名規約、コーディングスタイル
- `safety.md` — 環境に応じた許可/禁止操作
- `editing.md` — MCPツール参照の調整

## 連携オプション

### Discordボット

スマホ/ブラウザからの自動解析リクエスト:

1. Discordボットを作成（[Developer Portal](https://discord.com/developers/applications)）
2. トークンを `config/discord_bot_token.txt` に保存
3. Webhook URLを `config/discord_webhook.txt` に保存
4. `./scripts/start_discord_bot.sh` を実行
5. Discordチャンネルで `@request: <タスク>` を送信

詳細は `scripts/README_discord_bot.md` を参照。

### Notionログ

1. [Notion MCP連携](https://github.com/anthropics/claude-code)をセットアップ
2. `.claude/rules/communication.md` に親ページIDを設定
3. `/log-notion` スキルまたは自然言語で利用

## トラブルシューティング

| 問題 | 解決策 |
|-----|--------|
| SSH接続失敗 | `~/.ssh/config` を確認、VPNを確認、`ssh remote-server hostname` でテスト |
| リモートtmuxが存在しない | `ssh remote-server "tmux new -d -s claude"` または `init()` MCPツール |
| ローカルtmuxが存在しない | `./scripts/local_tmux_init.sh` |
| ROOTが見つからない | リモートシェル設定（`.bashrc`/`.cshrc`）を確認 |
| ROOTセッションが固まった | `run_kill()` → `run(".q")`、または `run("pkill -f root.exe")` |
| nvimがINSERTモードで固まった | `tmux send-keys -t remote-server:view.0 Escape` → `ZQ` |
| MCPサーバーが起動しない | `uv` がインストール済みか確認: `pip install uv` |
| シェルのクォート問題 | MCP `run(cmd)` はローカルtmux経由で処理 — 直接SSHは避ける |

## ライセンス

MIT License — 自由に実験に合わせて改変してください。

## 謝辞

- [Claude Code](https://claude.ai/code) by Anthropic
- [ROOT](https://root.cern/) by CERN
