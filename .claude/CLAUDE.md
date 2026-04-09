# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Principle

**Claude Code is a remote analysis operator, not a local developer.**

All source code, data, and build products exist only on the remote server. This local directory is controller-only. Operations are performed via MCP tools (primary) or CLI helper (fallback).

## Todo Workflow (IMPORTANT)

**Before starting any multi-step task:**
1. Create todo list -> 2. Present to user -> 3. **Ask approval** -> 4. Execute

See `.claude/rules/todo-workflow.md`

## Environment

> **IMPORTANT**: Edit these values to match your setup!
> Also edit the constants in `scripts/remote_mcp_server.py` and `scripts/ifarm_cli.sh`.

| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/analysis/directory/` |
| **Shell** | bash (or tcsh, zsh) |
| **SSH alias** | `myserver` (from ~/.ssh/config) |
| **Remote tmux session** | `claude` |
| **Local tmux session** | `myserver:view.0` |

## Architecture

```
MCP "remote-server" tools (primary)
 ├─ nvim tools:  open_file, replace, insert_after, bulk_insert, delete_lines, commit_edit
 ├─ terminal:    run, run_output, run_busy, run_kill
 ├─ sessions:    term_new, term_send, term_output, term_busy, term_kill, term_close
 ├─ files:       read_file, write_new_file
 └─ tabs:        tab_open, tab_list, tab_switch, tab_next, tab_prev, tab_close

./scripts/ifarm_cli.sh (fallback & extras)
 └─ findlines, vim-view, vim-pagedown/up/top/bottom, capture-screen, status
```

Two-layer transport:
1. **Local send-keys** (tmux send-keys -t local_pane) — ~0ms keystroke relay
2. **SSH** (ssh remote "...") — ~1.3s filesystem + remote tmux

## Quick Reference: Running Analysis

```
# MCP-based (primary)
init()                                    # Initialize session
run("cd $WORKDIR && <your-command>")      # Run command (auto-closes nvim)
run_busy()                                # Check if running
run_output(50)                            # Capture output

# File editing
open_file("macro/foo.C")                  # Open in nvim
replace("old", "new")                     # Single-line replace
commit_edit("macro/foo.C", "description") # Save
run(":q!")                                # Close nvim
```

## Custom Skills

| Skill | Description |
|-------|-------------|
| `/start-analysis <desc>` | Start analysis workflow (plan -> approve -> execute) |
| `/run-macro <name> [param]` | Run ROOT macro via tmux |
| `/check-tmux [lines]` | Check tmux session output |
| `/ifarm-status` | Verify SSH and tmux status |
| `/fetch-output <file> [type]` | Copy output files to local |
| `/check-root <file> [cmd]` | Inspect ROOT file contents |
| `/edit-ifarm <path> <old> <new>` | Edit remote files |
| `/kill-root [method]` | Stop stuck process |
| `/upload-qa <file> [desc]` | Upload QA plots to Discord (optional) |
| `/log-notion <title>` | Create Notion log entry (optional) |

## Agents

| Agent | Description |
|-------|-------------|
| **build-runner** | Run and debug analysis code on remote |
| **code-explorer** | Read-only codebase navigation |
| **data-inspector** | Inspect ROOT files and data quality |

## Allowed Operations

- MCP tools for file editing, command execution, session management
- CLI helper for batch grep, vim navigation, screen capture
- `scp` for fetching output files (PDF, ROOT)
- Create/update todo files in local `todo/` directory
- Upload QA plots to Discord, log to Notion (if configured)

## Forbidden Operations

- Local file editing outside `todo/` and `.claude/`
- Destructive commands: `rm -rf`, `chmod -R`, `chown`
- Analysis software only exists on remote (never run locally)
- Building or compiling locally

## Log-First Principle

Rely on log files, not tmux screen output:
```
run("tail -n 200 $WORKDIR/log/analysis.log")
run_output(50)

run("grep -n 'error' $WORKDIR/log/analysis.log")
run_output(50)
```

## Failure Handling

1. Inspect log file first
2. Explain technical cause
3. Propose minimal fix
4. Never retry blindly

## Path Reference

| Path | Description |
|------|-------------|
| `$WORKDIR/macro/` | Source code (run from here) |
| `$WORKDIR/param/` | Parameter files |
| `$WORKDIR/root/` | Output ROOT files |
| `$WORKDIR/pic/` | Output PDF files |
| `$WORKDIR/log/` | Analysis logs |
| `~/tmp/` | Temporary scripts |

## Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `block-dangerous.sh` | PreToolUse | Block `rm -rf`, `chmod -R`, etc. |
| `post-edit-reminder.sh` | PostToolUse | Remind to `commit_edit()` after edits |
| `stop-checkpoint.sh` | Stop | Post-task lesson logging reminder |
| `notify.sh` | Notification | macOS notification when input needed |
| `post-compact-context.sh` | PreCompact | Re-inject critical context after compaction |

## QA Upload Workflow (Optional)

```bash
# 1. Copy from remote
scp $SSH_ALIAS:$WORKDIR/pic/output.pdf QA/

# 2. Convert to PNG (macOS)
qlmanage -t -s 1200 -o QA/ QA/output.pdf

# 3. Upload via webhook
curl -F "file=@QA/output.pdf.png" \
     -F "content=QA: <description>" \
     "$(cat config/discord_webhook.txt)"
```

## Notion Logging (Optional)

```
mcp__notion__notion-create-pages
  parent: {"page_id": "YOUR-PAGE-ID-HERE"}
  pages: [{
    "properties": {"title": "YYYY-MM-DD: <Analysis Title>"},
    "content": "## Summary\n...\n\n## Results\n...\n\n## Status\nComplete"
  }]
```

## Documentation

| Topic | File |
|-------|------|
| **Analysis guide** | `docs/analysis_guide.md` |
| **Safety & ops** | `.claude/rules/safety.md` |
| **Editing workflow** | `.claude/rules/editing-policy.md` |
| **Todo workflow** | `.claude/rules/todo-workflow.md` |
| **Macro coding rules** | `.claude/rules/macro-rules.md` |
| **Macro editing** | `.claude/rules/macro-editing.md` |
| **Self-improvement** | `.claude/rules/self-improvement.md` |
| **Remote IDE** | `.claude/skills/remote-ide/SKILL.md` |
| **Analysis workflow** | `.claude/skills/analysis-workflow/SKILL.md` |
| **Job submission** | `.claude/skills/job-submission/SKILL.md` |
| **Add histogram** | `.claude/skills/add-histogram.md` |
| **Add canvas** | `.claude/skills/add-canvas.md` |
| **Add fitting** | `.claude/skills/add-fitting.md` |
| **Lessons** | `docs/lessons/*.md` |
| Your analysis docs | `docs/*.md` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Shell quoting errors | MCP `run(cmd)` sends via local tmux (handles quoting) |
| Process stuck | `run_kill()` or `term_close(name)` |
| nvim in wrong mode | MCP nvim tools send Escape first (automatic) |
| SSH dropped | ControlMaster auto-reconnects on next SSH call |
| Remote tmux session lost | `init()` recreates session |
| Local tmux session lost | `tmux new -d -s <session>` |
| Text not found in edit | Verify exact whitespace/newlines match |

## Human Responsibilities

- Interactive debugger or interpreter sessions
- Large-scale refactoring
- Final judgment on results
