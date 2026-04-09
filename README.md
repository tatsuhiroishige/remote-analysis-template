# Remote Analysis Template for Claude Code

A framework for controlling ROOT-based analysis on remote computing clusters using [Claude Code](https://claude.ai/code) as an AI-powered operator.

## Overview

This system enables you to run analyses on remote computing clusters through natural language conversation. Instead of manually SSH-ing, writing scripts, and monitoring jobs, you describe what you want and Claude handles the execution.

**Key Concept**: Claude Code acts as a *remote operator*, not a local developer. All source code, data, and computations exist on the remote server. This local repository contains only controller scripts, MCP server, and documentation.

## Features

- **MCP-Based Control**: FastMCP server provides structured tools for remote operations
- **Two-Layer Transport**: Local tmux relay (~0ms) + SSH (~1.3s) for optimal responsiveness
- **nvim Integration**: Full file editing via remote nvim with state safety guarantees
- **Parallel Sessions**: Run multiple jobs concurrently via tmux windows
- **Persistent Sessions**: tmux keeps analyses running even if connection drops
- **Safety Hooks**: PreToolUse hooks block dangerous commands, PostToolUse reminds to save
- **Agents**: Specialized sub-agents for building, exploring, and inspecting data
- **Automated Monitoring**: Claude watches progress and reports results
- **Integration**: Optional Discord/Notion logging for QA

---

## Quick Start

### 1. Prerequisites

- SSH access to a remote computing cluster
- ROOT installed on the remote server
- Claude Code CLI installed locally
- `uv` (Python package manager) for MCP server
- tmux on both local and remote machines

### 2. Clone this template

```bash
git clone https://github.com/YOUR_USERNAME/remote-analysis-template.git my-analysis
cd my-analysis
```

### 3. Setup SSH

Add to `~/.ssh/config`:

```
Host myserver
    HostName your-server.example.com
    User your-username
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    ServerAliveInterval 15
    ServerAliveCountMax 3
```

Create socket directory:
```bash
mkdir -p ~/.ssh/sockets
```

### 4. Configure constants

Edit the constants in these files to match your environment:

1. **`scripts/remote_mcp_server.py`** — `REMOTE`, `SESSION`, `WORKDIR`, `LOCAL_PANE`
2. **`scripts/ifarm_cli.sh`** — `REMOTE`, `SESSION`, `LOCAL_PANE`, `WORKDIR`
3. **`.claude/CLAUDE.md`** — Environment table
4. **`.claude/hooks/post-compact-context.sh`** — Context reminder message

### 5. Setup tmux sessions

```bash
# Remote: create tmux session
ssh myserver "tmux new-session -d -s claude -n ide -c ~/your/analysis/directory"

# Local: create tmux session with SSH view pane
tmux new-session -d -s myserver -n view
tmux send-keys -t myserver:view.0 "ssh myserver -t 'tmux attach -t claude'" Enter
```

### 6. Start Claude Code

```bash
claude
```

### 7. Run your first analysis

```
/start-analysis Run the acceptance study with default parameters
```

Or use natural language:
```
Run the acceptance study macro with 10 files
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Local Machine                       │
│                                                                  │
│  Claude Code CLI                                                 │
│  ├── MCP Server (scripts/remote_mcp_server.py)                  │
│  │   ├── nvim tools:  open_file, replace, insert_after, ...    │
│  │   ├── terminal:    run, run_output, run_busy, run_kill       │
│  │   ├── sessions:    term_new, term_send, term_output, ...    │
│  │   └── files:       read_file, write_new_file                 │
│  │                                                               │
│  ├── Layer 1: Local tmux send-keys (~0ms keystroke relay)       │
│  └── Layer 2: SSH commands (~1.3s filesystem + remote tmux)     │
│                                                                  │
│  Local tmux "myserver:view" ──SSH──► Remote tmux "claude:ide"   │
│                                                                  │
│  Hooks:                                                          │
│  ├── PreToolUse:  block-dangerous.sh (blocks rm -rf, etc.)      │
│  ├── PostToolUse: post-edit-reminder.sh (save reminders)        │
│  ├── Stop:        stop-checkpoint.sh (lesson logging)           │
│  └── Notification: notify.sh (macOS alerts)                     │
│                                                                  │
│  Agents:                                                         │
│  ├── build-runner (sonnet) — run & debug code                   │
│  ├── code-explorer (haiku) — read-only navigation               │
│  └── data-inspector (sonnet) — ROOT file inspection             │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ SSH / tmux send-keys
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Remote Server                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   tmux session: claude                     │  │
│  │   window: ide (single pane)                                │  │
│  │   + parallel windows via term_new()                        │  │
│  │                                                            │  │
│  │  • nvim opened on demand (not persistent)                 │  │
│  │  • Runs analysis code in batch mode                       │  │
│  │  • Generates output (ROOT, PDF)                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Working Directory ($WORKDIR):                                   │
│  ├── macro/    ← Source code (run from here)                    │
│  ├── param/    ← Parameter/configuration files                  │
│  ├── root/     ← Output ROOT files                              │
│  ├── pic/      ← Output PDF plots                               │
│  └── log/      ← Analysis logs                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

1. **Two-Layer Transport**: Local tmux relay for instant keystrokes, SSH for filesystem ops
2. **Fault Tolerance**: WiFi drops, laptop sleep — session persists, auto-reconnects
3. **Human Visibility**: Attach to local tmux read-only to watch operations live
4. **Safety**: Hooks block destructive commands, enforce save-after-edit discipline
5. **Parallel Work**: Named tmux windows for concurrent jobs without pane complexity

---

## Directory Structure

### Local (This Repository)

```
my-analysis/
├── .claude/
│   ├── CLAUDE.md              # Main configuration ← EDIT THIS
│   ├── settings.json          # MCP server + hooks configuration
│   ├── hooks/
│   │   ├── block-dangerous.sh     # Blocks rm -rf, chmod -R, etc.
│   │   ├── post-edit-reminder.sh  # Reminds to commit_edit()
│   │   ├── stop-checkpoint.sh     # Post-task lesson logging
│   │   ├── notify.sh             # macOS notification
│   │   └── post-compact-context.sh # Context after compaction
│   ├── rules/
│   │   ├── safety.md             # Operations policy (MCP-based)
│   │   ├── editing-policy.md     # File editing workflow + nvim safety
│   │   ├── macro-editing.md      # Macro editing patterns (ROOT)
│   │   ├── macro-rules.md        # Coding standards
│   │   ├── todo-workflow.md      # Task approval workflow
│   │   ├── self-improvement.md   # Lesson tracking
│   │   └── operations-policy.md  # Legacy SSH-direct reference
│   ├── agents/
│   │   ├── build-runner.md       # Run & debug analysis code
│   │   ├── code-explorer.md      # Read-only codebase navigation
│   │   └── data-inspector.md     # ROOT file inspection
│   └── skills/
│       ├── remote-ide/SKILL.md        # Core MCP operations
│       ├── analysis-workflow/SKILL.md # Analysis workflow patterns
│       ├── job-submission/SKILL.md    # Batch jobs + QA upload
│       ├── add-histogram.md     # Add ROOT histograms
│       ├── add-canvas.md        # Add canvas/PDF pages
│       ├── add-fitting.md       # Add fitting code
│       └── ...                  # Other skills
├── config/
│   └── discord_webhook.txt.example  # Discord webhook template
├── docs/
│   ├── analysis_guide.md       # Analysis guidance
│   └── lessons/                # Mistake tracking (self-improvement)
├── output/                     # Downloaded outputs
├── QA/                         # Downloaded QA plots
├── scripts/
│   ├── remote_mcp_server.py    # MCP server ← EDIT CONSTANTS
│   └── ifarm_cli.sh            # CLI fallback ← EDIT CONSTANTS
└── todo/
    └── todo_template.md        # Task specification template
```

### Remote (Your Working Directory)

Set up on your remote server:

```bash
ssh myserver "mkdir -p ~/analysis/{macro,param,root,pic,log} ~/tmp"
```

---

## MCP Tools Reference

### Session Management

| Tool | Description |
|------|-------------|
| `init()` | Create/restore remote tmux session |

### File Editing (via nvim)

| Tool | Description |
|------|-------------|
| `open_file(path)` | Open file in nvim |
| `replace(old, new)` | Single-line substitution |
| `delete_lines(start, end)` | Delete line range |
| `insert_after(line, text)` | Insert text after line |
| `bulk_insert(line, text)` | Insert large text block |
| `commit_edit(path, summary)` | Save + report changes |
| `read_file(path)` | Read file contents |
| `write_new_file(path, content)` | Create new file |

### Terminal

| Tool | Description |
|------|-------------|
| `run(cmd)` | Execute command (auto-closes nvim) |
| `run_output(lines)` | Capture recent output |
| `run_busy()` | Check if process running |
| `run_kill()` | Send Ctrl+C |

### Parallel Sessions

| Tool | Description |
|------|-------------|
| `term_new(name)` | Create named window |
| `term_send(name, cmd)` | Send command to window |
| `term_output(name, lines)` | Capture window output |
| `term_close(name)` | Kill window |

---

## Troubleshooting

### Connection Issues

**SSH fails:**
```bash
ssh myserver "hostname"
rm -rf ~/.ssh/sockets/*  # Reset control sockets
```

**Remote tmux missing:**
```bash
ssh myserver "tmux new-session -d -s claude -n ide"
```

**Local tmux missing:**
```bash
tmux new -d -s myserver
```

### Editing Issues

**nvim stuck in INSERT mode:**
```bash
tmux send-keys -t myserver:view.0 Escape
tmux send-keys -t myserver:view.0 'Z' 'Q'  # Force quit
```

**Process stuck:**
```
run_kill()  # Ctrl+C
# or
run("pkill -f '<process>'")
```

---

## Optional Integrations

### Discord (QA Uploads)

1. Create a Discord webhook in your server
2. Save URL to `config/discord_webhook.txt`
3. Use `/upload-qa` to share plots

### Notion (Logging)

1. Set up Notion MCP integration with Claude Code
2. Add your page ID to `.claude/CLAUDE.md`
3. Use `/log-notion` to create log entries

---

## Requirements

- macOS or Linux (local machine)
- SSH access to remote computing cluster
- ROOT installed on remote server
- tmux on both local and remote machines
- `uv` for MCP server (`pip install uv` or `brew install uv`)
- Claude Code CLI

## License

MIT License - Feel free to adapt for your experiment.

## Acknowledgments

- [Claude Code](https://claude.ai/code) by Anthropic
- [ROOT](https://root.cern/) by CERN
- [FastMCP](https://github.com/jlowin/fastmcp) for MCP server
