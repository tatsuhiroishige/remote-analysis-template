# check-tmux

Check the current output from the remote tmux session.

## Usage
```
/check-tmux [lines]
```

## Examples
```
/check-tmux
/check-tmux 50
/check-tmux 100
```

## Instructions

### 1. Capture tmux output
```bash
ssh $HOST "tmux capture-pane -t claude -p | tail -<lines>"
```
Default lines: 30

For extended history:
```bash
ssh $HOST "tmux capture-pane -t claude -p -S -200"
```

### 2. Parse status indicators

| Pattern | Status | Action |
|---------|--------|--------|
| `root [N]` | ROOT idle | Ready for command or `.q` |
| `Processing: X/Y` | Event loop | Running, wait |
| Shell prompt (`$` `%` `>`) | No ROOT | Analysis done or not started |
| `Error:` or `Warning:` | Issue | Report to user |

### 3. Extract key results
Look for standard output format:
```
step, n_total, n_after, efficiency
```

### 4. Report to user
Summarize:
- Current status (running/idle/complete)
- Progress if applicable
- Any errors or warnings
- Key numerical results

## Session Management

Check if session exists:
```bash
ssh $HOST "tmux has-session -t claude 2>/dev/null && echo 'Exists' || echo 'None'"
```

List all sessions:
```bash
ssh $HOST "tmux list-sessions"
```

## Notes
- Session name is `claude` (configurable in CLAUDE.md)
- Use `-S -N` for N lines of scrollback
