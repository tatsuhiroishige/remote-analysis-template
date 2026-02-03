# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Principle

**Claude Code is a remote analysis operator, not a local developer.**

All source code, data, and build products exist only on the remote server. This local directory is controller-only.

## Environment

> **IMPORTANT**: Edit these values to match your setup!

| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/analysis/directory/` |
| **Shell** | bash (or tcsh, zsh) |
| **SSH alias** | `myserver` (from ~/.ssh/config) |
| **tmux session** | `claude` |

## Quick Reference: Running Analysis

```bash
# 1. Create shell script locally (handles quoting issues)
cat > scripts/run_analysis.sh << 'EOF'
#!/bin/bash
cd $WORKDIR/macro
root -b -q 'macroName.C("../param/params.json")'
EOF

# 2. Transfer and execute via tmux
scp scripts/run_analysis.sh $HOST:~/tmp/
ssh $HOST "tmux send-keys -t claude 'bash ~/tmp/run_analysis.sh' Enter"

# 3. Monitor progress
ssh $HOST "tmux capture-pane -t claude -p | tail -30"

# 4. Exit ROOT when complete
ssh $HOST "tmux send-keys -t claude '.q' Enter"
```

## Custom Skills

| Skill | Description |
|-------|-------------|
| `/run-macro <name> [param]` | Run ROOT macro via tmux |
| `/check-tmux [lines]` | Check tmux session output |
| `/ifarm-status` | Verify SSH and tmux status |
| `/fetch-output <file> [type]` | Copy output files to local |
| `/check-root <file> [cmd]` | Inspect ROOT file contents |
| `/edit-ifarm <path> <old> <new>` | Edit remote files with Python patch |
| `/kill-root [method]` | Stop stuck ROOT session |
| `/upload-qa <file> [desc]` | Upload QA plots to Discord (optional) |
| `/log-notion <title>` | Create Notion log entry (optional) |

## Allowed Operations

- SSH/tmux operations with connection reuse
- Run analyses inside tmux session
- **Edit files on remote server** (always backup to `.bak` first)
- Save tmux output to local `output/` directory
- Upload QA plots to Discord, log to Notion

## Forbidden Operations

- Local file creation, editing, building, or git operations
- Destructive commands: `rm -rf`, `chmod -R`, `chown`
- ROOT only exists on the remote server

## Log-First Principle

Rely on log files, not tmux screen output:
```bash
ssh $HOST "tail -n 200 \$WORKDIR/log/analysis.log"
ssh $HOST "grep -n 'error' \$WORKDIR/log/analysis.log"
```

## Failure Handling

1. Inspect log file first
2. Explain technical/physics cause
3. Propose minimal fix
4. Never retry blindly

## Path Reference

| Path | Description |
|------|-------------|
| `$WORKDIR/macro/` | ROOT macros (run from here) |
| `$WORKDIR/param/` | JSON parameter files |
| `$WORKDIR/root/` | Output ROOT files |
| `$WORKDIR/pic/` | Output PDF files |
| `$WORKDIR/log/` | Analysis logs |
| `~/tmp/` | Temporary scripts |

## QA Upload Workflow (Optional)

```bash
# 1. Copy PDF from remote
scp $HOST:\$WORKDIR/pic/output.pdf QA/

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
    "content": "## Summary\n...\n\n## Results\n...\n\n## Status\n✓ Complete"
  }]
```

## Documentation

| Topic | File |
|-------|------|
| **Macro coding rules** | `.claude/rules/macro-rules.md` |
| **Macro creation guide** | `.claude/rules/macro-creation.md` |
| Your analysis docs | `docs/*.md` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Shell quoting errors | Use script files, don't pass parentheses directly |
| ROOT session stuck | `/kill-root` or `tmux send-keys -t claude C-c Enter` |
| Text not found in edit | Verify exact whitespace/newlines match |

## Human Responsibilities

- Interactive ROOT or debugger sessions
- Large-scale refactoring
- Final physics judgment
