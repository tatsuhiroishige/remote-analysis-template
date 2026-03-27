# Claude Code Remote Analysis Environment — Specification

## Overview

A system for editing and executing remote analysis code on remote servers using a local Claude Code (Max plan) instance, without installing Claude Code on the remote server.

**No SSHFS.** All operations are unified through SSH + tmux. The remote tmux session is laid out as an IDE with panes for a file browser, editor, and terminal. Every action Claude Code takes is visible in real time, allowing the human operator to monitor and intervene at any point.

---

## Design Principles

- **Transparency**: Every operation (file edits, command execution) is performed visibly through nvim and terminal commands, just as a human would
- **Diff reporting**: After each file edit, a unified diff is displayed and a summary is reported back to the user
- **Unified pathway**: All operations go through `ssh → tmux send-keys`. Zero dependency on SSHFS
- **Tab/window model**: Multiple files are managed via nvim tabs; multiple terminals via tmux windows — mirroring the IDE tab paradigm
- **Fault tolerance**: Dual tmux architecture (local + remote) ensures easy recovery from connection drops

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  Local Machine                                           │
│                                                          │
│  tmux session "remote-server"                               │
│    └── Claude Code CLI (Max plan)                        │
│          └── MCP server: remote-server (Python)           │
│                └── ssh() via SSH ControlMaster            │
│                                                          │
│  ~/.ssh/config                                           │
│    Host remote-server                                            │
│      ControlMaster auto                                  │
│      ControlPath ~/.ssh/cm-%r@%h:%p                      │
│      ControlPersist 10m                                  │
└───────────────────┬──────────────────────────────────────┘
                    │ SSH (single persistent connection)
┌───────────────────▼──────────────────────────────────────┐
│  Remote Server                                   │
│                                                          │
│  tmux session "claude"                                   │
│                                                          │
│  Window "ide" (default view):                            │
│  ┌───────────────────────────────────────────┐           │
│  │ nvim                                      │  pane 0   │
│  │ [ana.C] [fit.C] [Makefile]                │  Editor   │
│  │  ← nvim tab bar                           │           │
│  │  void Analysis() {                        │           │
│  │    if(cut > 1.5) {                        │           │
│  │    ...                                    │           │
│  ├───────────────────────────────────────────┤           │
│  │ $ make                                    │  pane 1   │
│  │ g++ -o analysis ...                       │  Terminal  │
│  └───────────────────────────────────────────┘           │
│                                                          │
│  Additional tmux windows (created on demand):            │
│  [0:ide] [1:build] [2:root] [3:job]                      │
│     ↑ status bar shows all windows as tabs               │
│                                                          │
│  /home/user/project/                                     │
│    ├── src/analysis.C                                    │
│    ├── Makefile                                          │
│    └── data/ → /volatile/...                             │
└──────────────────────────────────────────────────────────┘
```

### Monitoring

```bash
# Human operator attaches read-only from a separate terminal
ssh remote-server -t "tmux attach -t claude -r"

# All nvim edits, make output, diff results visible in real time
# -r (read-only) prevents interference with Claude's operations
# Remove -r to intervene manually when needed
# Switch windows with Ctrl+B n/p to check build, root, etc.
```

---

## Fault Tolerance

| Failure | Local tmux | Remote tmux | Recovery |
|---------|-----------|------------|----------|
| Wi-Fi blip | Connection holds | Process continues | Automatic |
| Laptop sleep | Session persists | Process continues | `tmux attach` |
| SSH timeout | Reconnectable | Process continues | `ssh` → `tmux attach` |
| Local PC reboot | Session lost | Process continues | New local tmux → `ssh` → `tmux attach` |
| Remote server reboot | Unaffected | Session lost | `init()` recreates |

---

## Components

### 1. SSH Configuration (`~/.ssh/config`)

ControlMaster allows all MCP ssh calls to multiplex over a single persistent connection.

```
Host remote-server
    HostName <REMOTE_HOSTNAME>
    User username
    ProxyJump <LOGIN_NODE>
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
    ServerAliveInterval 15
    ServerAliveCountMax 3
```

### 2. MCP Server (Unified Interface)

A Python script running locally. Provides all tools to Claude Code.

---

#### Constants & Core Functions

```python
import subprocess
import time

REMOTE = "remote-server"
SESSION = "claude"
WORKDIR = "/home/user/project"
SETUP_CMD = "source <SETUP_SCRIPT>"
SNAPSHOT_DIR = "~/.claude_snapshots"

# Pane targets (session:window.pane)
PANE_EDITOR = f"{SESSION}:ide.0"    # Editor (nvim) — top
PANE_TERM   = f"{SESSION}:ide.1"    # Terminal — bottom

def ssh(cmd: str, timeout: int = 30) -> str:
    """Execute a command on the remote server via SSH ControlMaster."""
    r = subprocess.run(
        ["ssh", REMOTE, cmd],
        capture_output=True, text=True, timeout=timeout
    )
    return r.stdout

def send(target: str, cmd: str):
    """Send a command string to a tmux pane/window (with Enter)."""
    escaped = cmd.replace("'", "'\\''")
    ssh(f"tmux send-keys -t {target} '{escaped}' Enter")

def send_keys(target: str, keys: str):
    """Send raw key sequences (no trailing Enter)."""
    ssh(f"tmux send-keys -t {target} {keys}")

def capture(target: str, lines: int = 50) -> str:
    """Capture visible output from a tmux pane."""
    return ssh(f"tmux capture-pane -t {target} -p -S -{lines}")

def is_busy(target: str) -> bool:
    """Check if a pane is running a foreground process."""
    pane_cmd = ssh(
        f"tmux display-message -t {target} -p '#{{pane_current_command}}'"
    )
    return pane_cmd.strip() not in ["bash", "zsh", "sh"]

def _snapshot_path(path: str) -> str:
    """Generate snapshot file path for diff tracking."""
    return f"{SNAPSHOT_DIR}/{path.replace('/', '__')}"
```

---

#### Tool Reference

##### Session Management

| Tool | Description |
|------|-------------|
| `init()` | Create 2-pane tmux layout: nvim + terminal (idempotent) |

```python
def init():
    """Create the IDE layout: nvim (top) + terminal (bottom) (idempotent)."""
    # Create session if not exists
    ssh(f"tmux has-session -t {SESSION} 2>/dev/null || "
        f"tmux new-session -d -s {SESSION} -n ide -c {WORKDIR}")

    # Split panes: top 65% (editor) | bottom 35% (terminal)
    pane_count = ssh(f"tmux list-panes -t {SESSION}:ide | wc -l").strip()
    if pane_count == "1":
        ssh(f"tmux split-window -v -t {SESSION}:ide.0 -c {WORKDIR} -l 35%")

    # Create snapshot directory
    ssh(f"mkdir -p {SNAPSHOT_DIR}")

    # Launch nvim in top pane (only if not already running)
    editor_cmd = ssh(
        f"tmux display-message -t {PANE_EDITOR} -p '#{{pane_current_command}}'"
    ).strip()
    if editor_cmd in ["bash", "zsh", "sh", "tcsh", "csh"]:
        send(PANE_EDITOR, "nvim")

    # Set up environment in the terminal pane
    send(PANE_TERM, SETUP_CMD)
```

---

##### Editor — File Operations (via nvim, all visible)

| Tool | Description | nvim command |
|------|-------------|-------------|
| `open_file(path)` | Open file + save snapshot | `:e {path}` |
| `goto_line(n)` | Jump to line | `:{n}` |
| `replace(old, new)` | Global substitution | `:%s/old/new/g` |
| `delete_lines(start, end)` | Delete line range | `:{s},{e}d` |
| `insert_after(line, text)` | Insert text after line | `:{n}r /tmp/...` |
| `write_new_file(path, content)` | Create new file | `:e` → `:r` → `:w` |
| `read_file(path)` | Get file contents (background, not displayed) | `ssh cat` |

```python
def nvim_cmd(cmd: str):
    """Send an Ex command to nvim (ensures normal mode first)."""
    send_keys(PANE_EDITOR, "Escape")
    time.sleep(0.05)
    send(PANE_EDITOR, f":{cmd}")

def open_file(path: str):
    """Open file in current nvim tab + save pre-edit snapshot."""
    full = f"{WORKDIR}/{path}"
    ssh(f"cp {full} {_snapshot_path(path)} 2>/dev/null || true")
    nvim_cmd(f"e {full}")

def goto_line(n: int):
    nvim_cmd(str(n))

def replace(old: str, new: str, flags: str = "g"):
    o = old.replace("/", "\\/")
    n = new.replace("/", "\\/")
    nvim_cmd(f"%s/{o}/{n}/{flags}")

def delete_lines(start: int, end: int):
    nvim_cmd(f"{start},{end}d")

def insert_after(line: int, text: str):
    """Insert text after the given line using :read (visible in nvim)."""
    subprocess.run(
        ["ssh", REMOTE, "cat > /tmp/.claude_insert"],
        input=text, text=True
    )
    nvim_cmd(f"{line}r /tmp/.claude_insert")

def write_new_file(path: str, content: str):
    """Create a new file: open buffer → insert content → save."""
    full = f"{WORKDIR}/{path}"
    nvim_cmd(f"e {full}")
    subprocess.run(
        ["ssh", REMOTE, "cat > /tmp/.claude_insert"],
        input=content, text=True
    )
    nvim_cmd("r /tmp/.claude_insert")
    nvim_cmd("1d")   # Remove leading blank line
    nvim_cmd("w")
    ssh(f"cp {full} {_snapshot_path(path)}")

def read_file(path: str) -> str:
    """Get file contents (read-only, runs in background — no need to display)."""
    return ssh(f"cat {WORKDIR}/{path}")
```

---

##### Editor — nvim Tab Management

Multiple files are kept open as nvim tabs, visible in the tab bar at the top of the editor pane — just like IDE tabs.

| Tool | Description | nvim command |
|------|-------------|-------------|
| `tab_open(path)` | Open file in a new tab + snapshot | `:tabedit {path}` |
| `tab_list()` | List all open tabs | `:tabs` |
| `tab_switch(n)` | Switch to tab n (1-indexed) | `:tabn {n}` |
| `tab_next()` | Next tab | `:tabnext` |
| `tab_prev()` | Previous tab | `:tabprev` |
| `tab_close()` | Close current tab | `:tabclose` |

```python
def tab_open(path: str):
    """Open file in a new nvim tab + save pre-edit snapshot."""
    full = f"{WORKDIR}/{path}"
    ssh(f"cp {full} {_snapshot_path(path)} 2>/dev/null || true")
    nvim_cmd(f"tabedit {full}")

def tab_list() -> str:
    """Get list of open nvim tabs (captures :tabs output)."""
    nvim_cmd("tabs")
    time.sleep(0.1)
    return capture(PANE_EDITOR, 20)

def tab_switch(n: int):
    """Switch to the nth tab (1-indexed)."""
    nvim_cmd(f"tabn {n}")

def tab_next():
    nvim_cmd("tabnext")

def tab_prev():
    nvim_cmd("tabprev")

def tab_close():
    nvim_cmd("tabclose")
```

---

##### Diff Reporting

| Tool | Description |
|------|-------------|
| `commit_edit(path, summary)` | Save → display diff → return report data |

```python
def commit_edit(path: str, summary: str) -> dict:
    """
    Finalize an edit: save file, show colored diff in terminal pane,
    and return diff data for Claude Code to report to the user.
    """
    full = f"{WORKDIR}/{path}"
    before = _snapshot_path(path)

    # 1. Save in nvim
    nvim_cmd("w")
    time.sleep(0.1)

    # 2. Get diff text (for Claude Code's chat report)
    diff_text = ssh(f"diff -u {before} {full} || true")

    # 3. Compute change stats from diff output (line-based for accuracy)
    lines = diff_text.splitlines()
    added = sum(1 for l in lines if l.startswith('+') and not l.startswith('+++'))
    removed = sum(1 for l in lines if l.startswith('-') and not l.startswith('---'))
    stat = f"{path}: +{added} -{removed}"

    # 4. Display colored diff in terminal pane (for human monitoring)
    send(PANE_TERM, f"echo '── {path} ──'")
    send(PANE_TERM,
        f"git diff --no-index --color --stat {before} {full} 2>/dev/null; "
        f"git diff --no-index --color {before} {full} 2>/dev/null || "
        f"diff --color -u {before} {full} || true"
    )

    # 5. Update snapshot (baseline for next edit)
    ssh(f"cp {full} {before}")

    return {
        "path": path,
        "summary": summary,
        "diff": diff_text,
        "stat": stat,
    }
```

---

##### Terminal — Default (ide window, pane 1)

| Tool | Description | Example |
|------|-------------|---------|
| `run(cmd)` | Execute command | `make`, `root -l -b -q macro.C` |
| `run_output(lines)` | Get terminal output | Check compile errors |
| `run_busy()` | Check if running | Monitor long jobs |
| `run_kill()` | Send Ctrl+C | Stop runaway process |

```python
def run(cmd: str):
    """Execute a command in the default terminal pane."""
    send(PANE_TERM, cmd)

def run_output(lines: int = 50) -> str:
    return capture(PANE_TERM, lines)

def run_busy() -> bool:
    return is_busy(PANE_TERM)

def run_kill():
    send_keys(PANE_TERM, "C-c")
```

---

##### Terminal — Additional Windows (tmux tabs)

Additional terminals are created as separate tmux windows, shown in the status bar like IDE tabs. This allows parallel execution (e.g., building in one terminal while running ROOT in another).

| Tool | Description |
|------|-------------|
| `term_new(name)` | Create a named terminal window |
| `term_send(name, cmd)` | Send command to a named terminal |
| `term_output(name, lines)` | Get output from a named terminal |
| `term_busy(name)` | Check if a named terminal is busy |
| `term_kill(name)` | Send Ctrl+C to a named terminal |
| `term_close(name)` | Close a terminal window |
| `term_list()` | List all open windows |

```python
def term_new(name: str):
    """Create a new named tmux window with environment setup."""
    ssh(f"tmux new-window -t {SESSION} -n {name} -c {WORKDIR}")
    send(f"{SESSION}:{name}", SETUP_CMD)

def term_send(name: str, cmd: str):
    """Send a command to the named terminal window."""
    send(f"{SESSION}:{name}", cmd)

def term_output(name: str, lines: int = 50) -> str:
    return capture(f"{SESSION}:{name}", lines)

def term_busy(name: str) -> bool:
    return is_busy(f"{SESSION}:{name}")

def term_kill(name: str):
    send_keys(f"{SESSION}:{name}", "C-c")

def term_close(name: str):
    """Close (kill) the named terminal window."""
    ssh(f"tmux kill-window -t {SESSION}:{name}")

def term_list() -> str:
    """List all tmux windows in the session."""
    return ssh(
        f"tmux list-windows -t {SESSION} "
        f"-F '#{{window_index}}:#{{window_name}} #{{window_active}}'"
    )
```

---

### 3. CLAUDE.md (Project Rules)

Place at `~/project/CLAUDE.md` to instruct Claude Code on how to operate in this remote environment.

```markdown
# <PARTICLE> Electroproduction Analysis

## Environment
- This project lives on a remote server
- All operations must go through MCP tools (no local files exist)
- Remote tmux session "claude" serves as the IDE

## File Editing Rules

### Opening & Editing
- First file: open_file(path) — opens in current nvim tab
- Additional files: tab_open(path) — opens in a new nvim tab
- Use tab_switch(n), tab_next(), tab_prev() to navigate
- Edit with replace(), delete_lines(), insert_after()

### After Every Edit: commit_edit()
Always call commit_edit(path, summary) after editing a file.
Report format:

  "Edited {path}:
   - {change 1}
   - {change 2}
   {stat output}
   Diff is displayed in the terminal pane."

Example:

  "Edited src/ana.C:
   - Changed MM2 cut threshold from 1.0 to 1.5
   - Removed unused fit function (lines 50-55)
   1 file changed, 2 insertions(+), 8 deletions(-)
   Diff is displayed in the terminal pane."

### Multi-file Edits
- Open each file with tab_open()
- Edit and commit_edit() each file individually
- Do NOT batch multiple files into a single report

## Command Execution

### Default terminal (ide pane)
- Build: run("make")
- ROOT macro: run("root -l -b -q 'macro.C(args)'")
- Check output: run_output()
- Check status: run_busy()

### Additional terminals
For parallel tasks, create named terminal windows:
- term_new("build") → term_send("build", "make")
- term_new("root") → term_send("root", "root -l data.root")
- term_new("job") → term_send("job", "batch system run ...")
- Check with term_output("build"), term_busy("root")
- Close when done: term_close("build")

## Coding Conventions
- ROOT 6 / C++17
- Histogram names: h_ prefix
- Cut variable names: descriptive (e.g., mm2_cut, w_min)
```

---

## Example Workflow

### Multi-file Edit → Build → Run

```
Claude Code                         Remote tmux (human monitoring)
───────────                        ─────────────────────────────────

open_file("src/ana.C")             nvim: :e src/ana.C
                                   tabs: [ana.C]

tab_open("src/fit.C")              nvim: :tabedit src/fit.C
                                   tabs: [ana.C] [fit.C]

tab_open("Makefile")               nvim: :tabedit Makefile
                                   tabs: [ana.C] [fit.C] [Makefile]

replace("old_func", "new_func")    nvim: :%s/old_func/new_func/g
                                   (in Makefile)

commit_edit("Makefile",            nvim: :w
  summary="Rename target")         terminal: diff --color -u ...

tab_switch(2)                      nvim: :tabn 2
                                   tabs: [ana.C] [fit.C] [Makefile]
                                                  ^ active

replace("OldFit", "NewFit")        nvim: :%s/OldFit/NewFit/g

commit_edit("src/fit.C",           nvim: :w
  summary="Rename fit function")   terminal: diff --color -u ...

tab_switch(1)                      nvim: :tabn 1 → ana.C

goto_line(42)                      nvim: :42
replace("cut>1.0", "cut>1.5")     nvim: :%s/cut>1.0/cut>1.5/g

commit_edit("src/ana.C",           nvim: :w
  summary="Update cut threshold")  terminal: diff --color -u ...
                                     - if(cut > 1.0) {
                                     + if(cut > 1.5) {

                                   Chat report:
                                     "Edited src/ana.C:
                                      - Changed cut threshold 1.0 → 1.5
                                      1 file changed, 1 insertion(+), 1 deletion(-)
                                      Diff is displayed in the terminal pane."

run("make")                        terminal: $ make
                                     g++ -std=c++17 -o analysis ...

run_output()                       (capture build output)

run("./analysis data.root")        terminal: $ ./analysis data.root
                                     Processing 10000 events...
```

### Parallel Terminal Usage

```
Claude Code                         Remote tmux
───────────                        ─────────────────────────────────

term_new("build")                  windows: [0:ide] [1:build]

term_new("root")                   windows: [0:ide] [1:build] [2:root]

term_send("build", "make -j4")     build window: $ make -j4
term_send("root",                  root window:  $ root -l data.root
  "root -l data.root")

term_busy("build")                 → True (compiling)
term_busy("root")                  → True (running)

term_output("build")               (check for errors)

term_close("build")                windows: [0:ide] [2:root]
```

### Human Monitoring View

```
ssh remote-server -t "tmux attach -t claude -r"

┌────────────────────────────────────────────────┐
│ nvim                                            │
│ [ana.C] [fit.C] [Makefile]                      │
│                                                 │
│  void Analysis() {                              │
│    if(cut > 1.5) {    ← just edited             │
│    ...                                          │
│                                                 │
├─────────────────────────────────────────────────┤
│ ── src/ana.C ──                                 │
│  1 file changed, 1 insertion(+), 1 deletion(-)  │
│ -  if(cut > 1.0) {                              │
│ +  if(cut > 1.5) {                              │
│ $                                               │
└─────────────────────────────────────────────────┘
 [0:ide*] [1:build] [2:root]   ← Ctrl+B n to switch
```

---

## Operations Guide

### Initial Setup

```bash
# 1. Add SSH config (ControlMaster)
# → See SSH Configuration section above

# 2. Register MCP server
# ~/.claude/settings.json
{
  "mcpServers": {
    "remote-server": {
      "command": "python3",
      "args": ["/path/to/remote_mcp_server.py"]
    }
  }
}

# 3. Start local tmux session
tmux new -s remote-server-work
claude
# → Tell Claude Code: "call init"
```

### Daily Workflow

```bash
# Open laptop
tmux attach -t remote-server-work

# Claude Code is already running (or restart with `claude`)
# All operations go through MCP → SSH → remote tmux

# Monitor from another terminal (optional)
ssh remote-server -t "tmux attach -t claude -r"
```

### Recovery

```bash
# SSH dropped → ControlMaster auto-reconnects on next call

# Remote tmux session lost → tell Claude Code: "call init"

# No SSHFS recovery needed (SSHFS is not used)
```

---

## Constraints

- **nvim send-keys**: Bulk text insertion uses `:read /tmp/file`. Sending line-by-line via send-keys is unreliable
- **nvim mode management**: Every nvim_cmd() sends `Escape` first to ensure normal mode
- **SSH ControlMaster lifetime**: `ControlPersist 10m` — idle connections close after 10 minutes but auto-reconnect on next ssh call
- **tmux capture-pane limits**: Output capture depends on scroll buffer. Use `-S -1000` for longer output
- **Remote network policy**: May require `ProxyJump` via `<LOGIN_NODE>`
- **File browser**: No file browser pane — use `run("ls")` or `term_send` for file listing

---

## Future Extensions

- **Anthropic native SSH connector**: [Issue #15208](https://github.com/anthropics/claude-code/issues/15208) proposes `claude --workspace user@server:/path`. Would eliminate the need for MCP
- **Persistent SSH sessions**: [Issue #13613](https://github.com/anthropics/claude-code/issues/13613) proposes tmux-based persistent remote sessions
- **tmuxp session definitions**: Replace `init()` with declarative YAML layouts via tmuxp
- **nvim LSP integration**: If clangd is available on remote server, nvim can provide autocomplete and diagnostics visible in the editor pane
