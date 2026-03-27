# Remote Analysis Framework for Claude Code

A framework for running ROOT-based physics analysis on remote computing servers using [Claude Code](https://claude.ai/code) as an AI-powered remote operator.

## Overview

This system lets you control particle physics analyses on remote servers through natural language conversation with Claude Code. Claude operates your remote server via an MCP (Model Context Protocol) server, editing files with nvim, running macros, and monitoring output — all through SSH + tmux with full visibility.

**Key Concept**: Claude Code acts as a *remote operator*. All source code, data, and computation live on the remote server. This local repository contains only the controller (MCP server, scripts, rules, documentation).

## Architecture

```
Local Machine                              Remote Server
┌────────────────────────────┐            ┌────────────────────────────┐
│  Claude Code CLI           │            │  tmux session "claude"     │
│    │                       │            │    │                       │
│    └─ MCP Server           │            │    ├─ nvim (file editing)  │
│       (remote_mcp_server.py)│           │    └─ terminal (commands)  │
│       │                    │            │                            │
│       ├─ Layer 1 ──────────┼──(tmux)──► │  (main pane, ~0ms)       │
│       └─ Layer 2 ──────────┼──(SSH)───► │  (parallel sessions, ~1s) │
│                            │            │                            │
│  tmux "remote-server"      │            │  Working Directory:        │
│    └─ pane 0: ssh attached │            │  ├── macro/   (ROOT macros)│
│       to remote tmux ──────┼───────────►│  ├── param/   (JSON config)│
│                            │            │  ├── root/    (output ROOT)│
│  Rules, Skills, Agents,    │            │  ├── pic/     (output PDF) │
│  Hooks                     │            │  └── log/     (logs)       │
└────────────────────────────┘            └────────────────────────────┘
```

### Two-Layer Command Transport

The MCP server uses **two distinct transport layers** to communicate with the remote server. This dual-layer design balances speed and capability.

```
                         ┌─────────────────────────────────────────┐
                         │         Layer 1: Local tmux relay       │
  Claude Code            │              (main pane)                │
    │                    │                                         │
    │  run("make")       │  tmux send-keys          Already SSH'd │
    │──────────────────► │  -t remote-server:view.0 ────────────► │ remote shell
    │                    │       (~0ms)              (persistent)  │ executes cmd
    │                    │                                         │
    │  run_output(50)    │  tmux capture-pane                     │
    │◄────────────────── │  -t remote-server:view.0 ◄──────────── │ screen content
    │                    └─────────────────────────────────────────┘
    │
    │                    ┌─────────────────────────────────────────┐
    │                    │        Layer 2: Direct SSH              │
    │                    │        (file I/O, parallel sessions)    │
    │                    │                                         │
    │  read_file(path)   │  ssh remote-server "cat <path>"        │
    │──────────────────► │       (~1.3s per call)                  │
    │                    │                                         │
    │  term_send(s, cmd) │  ssh remote-server                     │
    │──────────────────► │    "tmux send-keys -t <s> ..."         │
    │                    └─────────────────────────────────────────┘
```

**Layer 1 — Local tmux relay** (main pane commands: `run`, `run_output`, nvim editing)
- The local tmux pane (`remote-server:view.0`) maintains a persistent SSH connection to the remote tmux session
- Commands are sent as keystrokes via `tmux send-keys`, output is captured via `tmux capture-pane`
- **~0ms latency** — no SSH round-trip per command; the SSH connection is already established
- This is how nvim editing and macro execution work: keystrokes flow through the local pane to the remote terminal

**Layer 2 — Direct SSH** (file reads, parallel sessions: `read_file`, `term_send`, `term_output`)
- Used for operations that need structured output (file contents, remote tmux commands)
- Each call opens a new SSH invocation: `ssh remote-server "..."`
- **~1.3s latency** per call, but returns clean programmatic output
- SSH ControlMaster reuses the existing connection, so there's no authentication overhead

**Why two layers?**
- Layer 1 is fast but gives only screen-scraped output (what you'd see in a terminal)
- Layer 2 is slower but returns exact file contents and can target any remote tmux session
- nvim detection (INSERT mode, status bar) works by analyzing Layer 1 screen captures — no remote queries needed

### Components

1. **MCP Server** (`scripts/remote_mcp_server.py`) provides tools for file editing (via nvim), command execution, and session management through the two-layer transport
2. **Rules** (`.claude/rules/`) define coding conventions, editing workflow, safety policies, and communication style
3. **Skills** (`.claude/skills/`) are slash commands (`/analysis`, `/plotting`, `/remote-ide`, etc.) that guide Claude through common workflows
4. **Agents** (`.claude/agents/`) are specialized subagents for building, code exploration, data inspection, and physics review
5. **Hooks** (`.claude/hooks/`) enforce safety (block dangerous commands), remind about post-edit verification, and handle context compaction

## Prerequisites

### 1. SSH Access with ControlMaster

Add to `~/.ssh/config`:

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
ssh remote-server "echo 'Connection OK'"
```

### 2. Remote tmux Session

```bash
ssh remote-server "tmux new-session -d -s claude"
```

### 3. Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

### 4. Python Dependencies (for MCP server)

```bash
pip install mcp  # or: uv add mcp
```

### 5. ROOT on Remote Server

Ensure ROOT is available in your remote shell environment (`.bashrc`, `.cshrc`, etc.):

```bash
source /path/to/root/bin/thisroot.sh
```

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/tatsuhiroishige/remote-analysis-template.git
cd remote-analysis-template
```

### 2. Edit configuration

Update these files with your server details:

| File | What to change |
|------|---------------|
| `.claude/CLAUDE.md` | WORKDIR, shell type, tmux session names |
| `scripts/remote_mcp_server.py` | `REMOTE`, `WORKDIR`, `SETUP_CMD`, `LOCAL_PANE` |
| `scripts/remote_cli.sh` | `REMOTE`, `WORKDIR`, `LOCAL_PANE` |
| `scripts/local_tmux_init.sh` | SSH alias, tmux session name |

### 3. Initialize local tmux

```bash
./scripts/local_tmux_init.sh
```

### 4. Start Claude Code

```bash
claude
```

### 5. Start working

```
> Run the study macro with default parameters
> Check if it's still running
> Show me the output PDF
```

## Directory Structure

### Local (This Repository)

```
remote-analysis-template/
├── .claude/
│   ├── CLAUDE.md                  # Main configuration (EDIT THIS)
│   ├── settings.json              # MCP server & hooks config
│   ├── rules/
│   │   ├── coding.md              # Coding conventions (ROOT/C++)
│   │   ├── editing.md             # Remote file editing workflow (MCP tools)
│   │   ├── safety.md              # Allowed/forbidden operations
│   │   ├── communication.md       # Todo workflow, Discord, Notion logging
│   │   ├── documentation.md       # Auto-update docs policy
│   │   └── self-improvement.md    # Lesson tracking from mistakes
│   ├── skills/
│   │   ├── analysis/SKILL.md      # /analysis — full analysis workflow
│   │   ├── remote-ide/SKILL.md    # /remote-ide — session management
│   │   ├── plotting/SKILL.md      # /plotting — ROOT plotting & QA upload
│   │   ├── job-submission/SKILL.md # /job-submission — batch jobs
│   │   ├── monte-carlo/SKILL.md   # /monte-carlo — MC simulation
│   │   ├── data-reading/SKILL.md  # /data-reading — data format & API
│   │   ├── log-notion/SKILL.md    # /log-notion — Notion logging
│   │   └── notebooklm-research/SKILL.md  # /notebooklm-research
│   ├── agents/
│   │   ├── build-runner.md        # Compile & run macros
│   │   ├── code-explorer.md       # Read-only codebase navigation
│   │   ├── data-inspector.md      # ROOT file inspection
│   │   ├── knowledge-researcher.md # Web/NotebookLM research
│   │   └── physics-reviewer.md    # Physics correctness review
│   └── hooks/
│       ├── block-dangerous.sh     # Block rm -rf, chmod -R, etc.
│       ├── post-edit-reminder.sh  # Remind to commit_edit after edits
│       ├── post-compact-context.sh # Inject context after compaction
│       ├── stop-checkpoint.sh     # Post-task lesson/doc checkpoint
│       └── notify.sh              # macOS notification on completion
├── scripts/
│   ├── remote_mcp_server.py       # MCP server (primary interface)
│   ├── remote_cli.sh              # CLI helper (fallback/extras)
│   ├── local_tmux_init.sh         # Local tmux session setup
│   ├── discord_bot.py             # Discord bot for remote requests
│   └── start_discord_bot.sh       # Bot startup script
├── config/
│   └── discord_webhook.txt.example # Discord webhook URL template
├── docs/                          # Analysis knowledge base
├── todo/                          # Task tracking
│   └── todo_template.md           # Standard todo format
├── output/                        # Downloaded output files
├── QA/                            # Downloaded QA plots
├── .mcp.json                      # MCP server registration
└── .gitignore
```

### Remote (Your Working Directory)

```
<PROJECT_DIR>/
├── macro/          # ROOT analysis macros
│   ├── commonFunctions.C
│   ├── commonParams.C
│   ├── ReadParam.C
│   └── yourAnalysis.C
├── param/          # JSON parameter files
├── common/         # Shared modules
├── root/           # Output ROOT files
├── pic/            # Output PDF files
└── log/            # Analysis logs
```

## MCP Tools Reference

The MCP server exposes these tools to Claude:

### File Editing (via nvim)

| Tool | Description |
|------|-------------|
| `open_file(path)` | Open file in nvim |
| `replace(old, new)` | Global substitution |
| `insert_after(line, text)` | Insert text after line |
| `bulk_insert(line, text)` | Insert large block |
| `delete_lines(start, end)` | Delete line range |
| `commit_edit(path, summary)` | Save + generate diff report |
| `read_file(path)` | Read file contents |
| `write_new_file(path, content)` | Create new file |

### Command Execution

| Tool | Description |
|------|-------------|
| `run(cmd)` | Execute command (auto-closes nvim) |
| `run_output(lines)` | Capture terminal output |
| `run_busy()` | Check if process is running |
| `run_kill()` | Send Ctrl+C |

### Parallel Sessions

| Tool | Description |
|------|-------------|
| `term_new(name)` | Create named tmux session |
| `term_send(name, cmd)` | Send command to session |
| `term_output(name, lines)` | Capture session output |
| `term_close(name)` | Kill session |

### nvim Tabs

| Tool | Description |
|------|-------------|
| `tab_open(path)` | Open file in new tab |
| `tab_list()` | List open tabs |
| `tab_switch(n)` | Switch to tab n |
| `tab_close()` | Close current tab |

## Customization Guide

### Step 1: Server Configuration

Edit `scripts/remote_mcp_server.py`:

```python
REMOTE = "remote-server"           # Your SSH alias
SESSION = "claude"                  # Remote tmux session name
WORKDIR = "/home/<USER>/<PROJECT>"  # Remote working directory
SETUP_CMD = "source <SETUP_SCRIPT>" # Environment setup command
LOCAL_PANE = "remote-server:view.0" # Local tmux pane
```

### Step 2: CLAUDE.md

Edit `.claude/CLAUDE.md` with your environment details (WORKDIR, shell, tmux names).

### Step 3: Add Your Documentation

Build up `docs/` as you work. Recommended structure:

```
docs/
├── analysis/       # Your analysis methods, cuts, results
├── experiment/     # Experiment knowledge (detectors, PID, kinematics)
├── root-api/       # ROOT/framework coding patterns
├── simulation/     # MC generation chain
├── computing/      # Remote server infrastructure
├── workflow/       # Notion, Discord, QA procedures
└── lessons/        # Mistake log for self-improvement
```

### Step 4: Adapt Rules

Review and edit `.claude/rules/`:
- `coding.md` — Your macro naming conventions and coding style
- `safety.md` — Allowed/forbidden operations for your environment
- `editing.md` — Adjust MCP tool references if needed

## Integration Options

### Discord Bot

Automated analysis requests from your phone/browser:

1. Create a Discord bot ([Developer Portal](https://discord.com/developers/applications))
2. Save token to `config/discord_bot_token.txt`
3. Save webhook URL to `config/discord_webhook.txt`
4. Run `./scripts/start_discord_bot.sh`
5. Send `@request: <task>` in your Discord channel

See `scripts/README_discord_bot.md` for full setup guide.

### Notion Logging

1. Set up [Notion MCP integration](https://github.com/anthropics/claude-code)
2. Set parent page ID in `.claude/rules/communication.md`
3. Use `/log-notion` skill or natural language

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection fails | Check `~/.ssh/config`, verify VPN, test with `ssh remote-server hostname` |
| Remote tmux missing | `ssh remote-server "tmux new -d -s claude"` or use `init()` MCP tool |
| Local tmux missing | `./scripts/local_tmux_init.sh` |
| ROOT not found | Check remote shell config (`.bashrc`/`.cshrc`) |
| ROOT session stuck | `run_kill()` then `run(".q")`, or `run("pkill -f root.exe")` |
| nvim stuck in INSERT | `tmux send-keys -t remote-server:view.0 Escape` then `ZQ` |
| MCP server not starting | Check `uv` is installed: `pip install uv` |
| Shell quoting errors | MCP `run(cmd)` handles quoting via local tmux — avoid raw SSH |

## License

MIT License — Feel free to adapt for your experiment.

## Acknowledgments

- [Claude Code](https://claude.ai/code) by Anthropic
- [ROOT](https://root.cern/) by CERN
