---
name: remote-ide
description: tmux remote operation, remote connectivity, session management, and troubleshooting
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

./scripts/remote_cli.sh (fallback & extras)
 └─ findlines, vim-view, vim-pagedown/up/top/bottom, capture-screen, status
```

**MCP tools are the primary interface.** `remote_cli.sh` is for features MCP doesn't cover.

## Layout

Remote tmux session `claude`, window `ide`: single pane (terminal).
nvim is opened on demand, not persistent.

## Session Management

### Initialize / Recover

```
init()   # Create/restore remote tmux session (idempotent)
```

If local tmux session `remote-server` is missing:
```bash
tmux new -d -s remote-server  # then attach SSH in pane 0
```

### Check Status

```
run_busy()           # Is something running?
run_output(10)       # Recent output
term_list()          # All tmux sessions
```

## Remote Server Status Check

| Check | How |
|-------|-----|
| SSH alive | `run("hostname")` + `run_output()` |
| Remote tmux | `term_list()` |
| WORKDIR exists | `run("ls macro/*.C \| wc -l")` + `run_output()` |
| root | `run("which root")` + `run_output()` |
| Recent output | `run("ls -lt root/*.root \| head -3")` + `run_output()` |

### Recovery Actions

**SSH fails:** Check `~/.ssh/config` for `remote-server` alias, verify VPN.

**Remote tmux session missing:** `init()` or `ssh remote-server "tmux new -d -s claude"`.

**Local tmux session missing:** `tmux new -d -s remote-server`.

**root not found:** Check `.login` or `.cshrc`.

## File Editing

nvim is opened on demand via MCP tools:

```
# Open file
open_file("macro/foo.C")

# Substitution
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

### Batch Grep (findlines) — remote_cli.sh only

Find line numbers in a single SSH call:

```bash
./scripts/remote_cli.sh findlines templateFit.C 'void templateFit\|class BinAna\|=== SECTION'
```

### Efficient Multi-Point Editing

1. **findlines** — get all target line numbers in one call
2. **Insert bottom-to-top** — highest line first so earlier numbers don't shift
3. `insert_after(line, text)` for each point
4. Single `commit_edit()` at the end

## Navigation

```
goto_line(100)              # Jump to line in nvim

# For scrolling (remote_cli.sh only):
./scripts/remote_cli.sh vim-view 100     # Jump + capture
./scripts/remote_cli.sh vim-pagedown     # C-d
./scripts/remote_cli.sh vim-pageup       # C-u
./scripts/remote_cli.sh vim-top          # gg
./scripts/remote_cli.sh vim-bottom       # G
```

## Running Macros

### Standard Pattern

```
# run() auto-closes nvim if open
run("cd macro && root -l -b -q 'macroName.C(\"../param/params.json\")'")
```

### Monitor Progress

```
run_busy()          # Check process
run_output(50)      # See output
```

### Parallel Execution (separate sessions)

```
term_new("job1")
term_send("job1", "cd macro && root -l -b -q 'macro1.C'")

term_new("job2")
term_send("job2", "cd macro && root -l -b -q 'macro2.C'")

term_output("job1", 50)
term_output("job2", 50)

term_close("job1")
term_close("job2")
```

## Killing Stuck Processes

```
Is ROOT responding?
├── Yes (shows "root [N]") → run(".q")
├── Slow (Processing...) → run_kill() then run(".q")
└── No response → run("pkill -f 'root|root.exe'")
```

## Fetching Output Files

```bash
scp remote-server:$WORKDIR/root/<file>.root /Users/<LOCAL_USER>/path/to/remote-analysis/output/
scp remote-server:$WORKDIR/pic/<file>.pdf /Users/<LOCAL_USER>/path/to/remote-analysis/QA/
```

## Common Issues

| Issue | Solution |
|-------|----------|
| tcsh quoting errors | MCP `run(cmd)` sends via local tmux (handles quoting) |
| ROOT stuck | `run_kill()` then check `run_busy()` |
| nvim in wrong mode | MCP nvim tools send Escape first (automatic) |
| SSH dropped | ControlMaster auto-reconnects on next call |
| Remote tmux session lost | `init()` to recreate |
| Local tmux session lost | `tmux new -d -s remote-server` |
| `grep -P` fails | Remote grep doesn't support `-P`; use `-o` with basic regex |
| capture出力にmodule loadメッセージ混入 | SSH接続時のmodule load出力。実害なし、出力末尾を読めばOK |
| `\rm` vs `rm` on remote server | `rm` is aliased to `rm -i`. Use `\rm` to skip confirmation |

## Knowledge References

- [docs/root/macros/execution.md](../../docs/root/macros/execution.md) — Macro execution patterns and progress indicators
- [docs/root/macros/paths.md](../../docs/root/macros/paths.md) — WORKDIR paths and directory layout
- [docs/root/io/inspection.md](../../docs/root/io/inspection.md) — ROOT file inspection commands
