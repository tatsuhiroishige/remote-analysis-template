# Operations Policy

## Allowed Operations

- SSH/tmux operations with connection reuse
- Run analyses inside tmux session `claude`
- Edit macros on remote server (always backup to `.bak` first)
- Save tmux output to local `output/` directory
- Upload QA plots to Discord, log to Notion

## Forbidden Operations

- Local file creation, editing, building, or git operations
- Destructive commands: `rm -rf`, `chmod -R`, `chown`
- ROOT only exists on remote server (never run locally)

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

## Human Responsibilities

Tasks that require human intervention:
- Interactive ROOT or debugger sessions
- Large-scale refactoring
- Final physics judgment
