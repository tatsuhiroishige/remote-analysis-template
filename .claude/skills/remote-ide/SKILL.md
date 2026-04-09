---
name: remote-ide
description: tmux remote operation, connectivity, session management, and troubleshooting
---

# Remote Operations

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

**MCP tools are the primary interface.** CLI helper is for features MCP doesn't cover.

## Layout

Remote tmux session, window `ide`: single pane (terminal).
nvim is opened on demand, not persistent.

## Session Management

### Initialize / Recover

```
init()   # Create/restore remote tmux session (idempotent)
```

If local tmux session is missing:
```bash
tmux new -d -s <session>  # then attach SSH in pane 0
```

### Check Status

```
run_busy()           # Is something running?
run_output(10)       # Recent output
term_list()          # All tmux windows
```

## Status Check

| Check | How |
|-------|-----|
| SSH alive | `run("hostname")` + `run_output()` |
| Remote tmux | `term_list()` |
| WORKDIR exists | `run("ls $WORKDIR")` + `run_output()` |
| Recent output | `run("ls -lt $WORKDIR/output/")` + `run_output()` |

### Recovery Actions

**SSH fails:** Check `~/.ssh/config` for alias, verify VPN/network.

**Remote tmux session missing:** `init()` recreates it.

**Local tmux session missing:** `tmux new -d -s <session>`.

## File Editing

nvim is opened on demand via MCP tools:

```
# Open file
open_file("macro/foo.C")

# Substitution (single-line only)
replace("old_text", "new_text")

# Insert after line 123
insert_after(123, "// new code\nint x = 42;")

# Large block insertion
bulk_insert(100, "line1\nline2\nline3")

# Delete lines
delete_lines(42, 50)

# Save + report
commit_edit("macro/foo.C", "Updated cut values")

# Verify
read_file("macro/foo.C")
```

### Batch Grep (findlines) — CLI helper only

Find line numbers in a single SSH call:

```bash
./scripts/ifarm_cli.sh findlines <file> '<pattern>'
```

### Efficient Multi-Point Editing

1. **findlines** — get all target line numbers in one call
2. **Insert bottom-to-top** — highest line first so earlier numbers don't shift
3. `insert_after(line, text)` for each point
4. Single `commit_edit()` at the end

## Navigation

```
goto_line(100)              # Jump to line in nvim

# For scrolling (CLI helper only):
./scripts/ifarm_cli.sh vim-view 100     # Jump + capture
./scripts/ifarm_cli.sh vim-pagedown     # C-d
./scripts/ifarm_cli.sh vim-pageup       # C-u
```

## Running Commands

### Standard Pattern

```
# run() auto-closes nvim if open
run("cd $WORKDIR && <your-command>")
```

### Monitor Progress

```
run_busy()          # Check process
run_output(50)      # See output
```

### Parallel Execution (separate windows)

```
term_new("job1")
term_send("job1", "cd $WORKDIR && <command1>")

term_new("job2")
term_send("job2", "cd $WORKDIR && <command2>")

term_output("job1", 50)
term_output("job2", 50)

term_close("job1")
term_close("job2")
```

## Killing Stuck Processes

```
Is the process responding?
├── Yes → run("<quit-command>")
├── Slow → run_kill() then run("<quit-command>")
└── No response → run("pkill -f '<process-name>'")
```

## Fetching Output Files

```bash
scp $SSH_ALIAS:$WORKDIR/output/<file> ./output/
scp $SSH_ALIAS:$WORKDIR/pic/<file>.pdf ./QA/
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Shell quoting errors | MCP `run(cmd)` sends via local tmux (handles quoting) |
| Process stuck | `run_kill()` then check `run_busy()` |
| nvim in wrong mode | MCP nvim tools send Escape first (automatic) |
| SSH dropped | ControlMaster auto-reconnects on next call |
| Remote tmux session lost | `init()` to recreate |
| Local tmux session lost | `tmux new -d -s <session>` |
