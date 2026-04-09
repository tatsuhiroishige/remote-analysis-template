#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp[cli]"]
# ///
"""
Remote MCP Server — No Socket, CLI-based

Two-layer transport:
  1. Local send-keys  (tmux send-keys -t <local_pane>)  → ~0ms   keystroke relay
  2. SSH              (ssh <remote> "...")                → ~1.3s  filesystem + remote tmux

Architecture:
  - Main session has a single pane (terminal)
  - nvim is opened on demand, not persistent
  - Parallel tasks use separate tmux windows (term_new)
  - No socket forwarding needed

Usage:
    Registered in .claude/settings.json as the "remote-server" MCP server.
    Claude Code launches this automatically via stdio transport.

Setup:
    1. Edit the Constants section below to match your environment
    2. Ensure SSH config has ControlMaster for connection reuse
    3. Create local tmux session: tmux new -d -s <LOCAL_SESSION>
    4. In the local pane, SSH into remote and attach to tmux session
"""

import os
import shlex
import subprocess
import time
import re

from mcp.server.fastmcp import FastMCP

# ──────────────────────────────────────────────
# Constants — EDIT THESE TO MATCH YOUR SETUP
# ──────────────────────────────────────────────

REMOTE = "myserver"                          # SSH alias from ~/.ssh/config
SESSION = "claude"                           # Remote tmux session name
WORKDIR = "/home/user/analysis"              # Remote working directory
SETUP_CMD = ""                               # Optional: env setup command (e.g. "source /opt/env.sh")

# Local tmux pane that is SSH'd into remote server
LOCAL_PANE = "myserver:view.0"               # <local_session>:<window>.<pane>

# Remote pane target (single pane)
PANE_MAIN = f"{SESSION}:ide.0"

# Shell names that indicate an idle prompt
IDLE_SHELLS = ("bash", "zsh", "sh", "tcsh", "csh")

# Remote tmux prefix key (default: C-b, some configs use C-a)
REMOTE_TMUX_PREFIX = "C-b"

# ──────────────────────────────────────────────
# Layer 1: Local tmux (instant keystrokes)
# ──────────────────────────────────────────────


def _local_send_keys(*args: str):
    """Send keys to the local tmux pane (instant, no SSH)."""
    subprocess.run(["tmux", "send-keys", "-t", LOCAL_PANE, *args], check=False)


def _local_send_literal(text: str):
    """Send literal text to the local tmux pane (no interpretation).
    Note: -l flag loses semicolons through local->SSH->remote tmux relay.
    Fix: split on ';', send text parts with -l, send ';' with -H 3b (hex).
    """
    if ";" not in text:
        subprocess.run(
            ["tmux", "send-keys", "-t", LOCAL_PANE, "-l", text], check=False
        )
    else:
        parts = text.split(";")
        for i, part in enumerate(parts):
            if part:
                subprocess.run(
                    ["tmux", "send-keys", "-t", LOCAL_PANE, "-l", part], check=False
                )
            if i < len(parts) - 1:
                subprocess.run(
                    ["tmux", "send-keys", "-t", LOCAL_PANE, "-H", "3b"], check=False
                )


def _local_capture(lines: int = 50) -> str:
    """Capture visible output from the local tmux pane."""
    r = subprocess.run(
        ["tmux", "capture-pane", "-t", LOCAL_PANE, "-p", "-S", f"-{lines}"],
        capture_output=True, text=True, timeout=5,
    )
    return r.stdout


# ──────────────────────────────────────────────
# Layer 2: SSH (filesystem + remote tmux)
# ──────────────────────────────────────────────


def _ssh(cmd: str, timeout: int = 30, input_text: str | None = None) -> str:
    """Execute a command on remote server via SSH."""
    r = subprocess.run(
        ["ssh", REMOTE, cmd],
        capture_output=True, text=True, timeout=timeout,
        input=input_text,
    )
    # Filter out module load messages (common on HPC systems)
    lines = r.stdout.splitlines()
    filtered = [l for l in lines if not re.match(r'^\s*(Loading |WARNING|requirement)', l)]
    return "\n".join(filtered)


def _rtmux(*args: str, timeout: int = 10) -> str:
    """Execute a tmux command on remote via SSH."""
    cmd = f"tmux {' '.join(args)}"
    return _ssh(cmd, timeout=timeout)


# ──────────────────────────────────────────────
# Composite helpers
# ──────────────────────────────────────────────


def send(cmd: str):
    """Send a command string to the main pane (with Enter)."""
    _local_send_literal(cmd)
    _local_send_keys("Enter")


def send_to(target: str, cmd: str):
    """Send a command string to a specific remote target (with Enter)."""
    _rtmux("send-keys", "-t", target, "-l", f"'{cmd}'")
    _rtmux("send-keys", "-t", target, "Enter")


def send_keys_raw(target: str, keys: str):
    """Send raw key sequences (no trailing Enter)."""
    if target == PANE_MAIN:
        _local_send_keys(keys)
    else:
        _rtmux("send-keys", "-t", target, keys)


def capture(target: str, lines: int = 50) -> str:
    """Capture visible output from a tmux pane."""
    if target == PANE_MAIN:
        return _local_capture(lines)
    return _rtmux("capture-pane", "-t", target, "-p", "-S", f"-{lines}")


def is_busy_local() -> bool:
    """Check if main pane is busy by looking at last line of capture."""
    output = _local_capture(5)
    last = ""
    for line in reversed(output.splitlines()):
        if line.strip():
            last = line.strip()
            break
    return not (last.endswith("$") or last.endswith("%"))


def is_busy_remote(target: str) -> bool:
    """Check if a remote pane is running a foreground process."""
    pane_cmd = _rtmux(
        "display-message", "-t", target, "-p", "'#{pane_current_command}'"
    )
    return pane_cmd.strip() not in IDLE_SHELLS


def _resolve_path(path: str) -> str:
    """Resolve path: absolute paths (/, ~/) pass through, relative paths get WORKDIR prepended."""
    if path.startswith("/") or path.startswith("~/"):
        return path
    return f"{WORKDIR}/{path}"


def _is_nvim_running() -> bool:
    """Check if nvim is running by examining local tmux pane content.

    Cannot use pane_current_command because:
    - Local tmux always shows 'ssh'
    - Remote tmux via SSH is slow (~1.3s) and noisy (module messages)

    Instead, detect nvim by its distinctive visual patterns:
    - Mode indicators: -- INSERT --, -- VISUAL --, -- REPLACE --
    - Status bar: line,col followed by All/Top/Bot/NN%
    """
    output = _local_capture(5)
    if not output:
        return False
    # Mode indicators (INSERT, VISUAL, REPLACE)
    if re.search(r'-- (INSERT|VISUAL|REPLACE)', output):
        return True
    # nvim status bar: line,col + position indicator (e.g. "3,1  All" or "150,12  42%")
    lines = output.strip().splitlines()
    for line in lines[-3:]:
        if re.search(r'\d+,\d+\s+(All|Top|Bot|\d+%)', line):
            return True
    return False


def _ensure_nvim():
    """Start nvim in the main pane if not already running."""
    if not _is_nvim_running():
        send("nvim")
        for _ in range(10):
            time.sleep(0.3)
            if _is_nvim_running():
                return
        time.sleep(0.5)


def _escape_to_normal():
    """Send Escape twice with delay to reliably exit INSERT/VISUAL mode."""
    _local_send_keys("Escape")
    time.sleep(0.1)
    _local_send_keys("Escape")
    time.sleep(0.1)


def _exit_nvim():
    """Force-exit nvim reliably. Returns True if nvim exited."""
    if not _is_nvim_running():
        return True
    # 1. Escape to normal mode (triple Escape for safety)
    for _ in range(3):
        _local_send_keys("Escape")
        time.sleep(0.1)
    # 2. Save all and quit
    _local_send_literal(":wa")
    _local_send_keys("Enter")
    time.sleep(0.1)
    _local_send_keys("Escape")
    time.sleep(0.05)
    _local_send_literal(":qa!")
    _local_send_keys("Enter")
    time.sleep(0.15)
    # 3. Wait for exit (up to 3s)
    for _ in range(30):
        if not _is_nvim_running():
            return True
        time.sleep(0.1)
    # 4. Fallback: ZQ (quit without saving)
    _local_send_keys("Escape")
    time.sleep(0.1)
    _local_send_keys("Z")
    time.sleep(0.05)
    _local_send_keys("Q")
    time.sleep(0.3)
    return not _is_nvim_running()


def nvim_cmd(cmd: str):
    """Send an Ex command to nvim (ensures normal mode first and last)."""
    _ensure_nvim()
    _escape_to_normal()
    _local_send_literal(f":{cmd}")
    time.sleep(0.05)
    _local_send_keys("Enter")
    time.sleep(0.1)
    _escape_to_normal()


# ──────────────────────────────────────────────
# MCP Server
# ──────────────────────────────────────────────

mcp = FastMCP("remote-server")

# ──────────────────────────────────────────────
# Session Management
# ──────────────────────────────────────────────


@mcp.tool()
def init() -> str:
    """Create the main session with a single pane (idempotent)."""
    _ssh(
        f"tmux has-session -t {SESSION} 2>/dev/null || "
        f"tmux new-session -d -s {SESSION} -n ide -c {WORKDIR}"
    )

    # Verify local tmux session exists
    local_session = LOCAL_PANE.split(":")[0]
    r = subprocess.run(
        ["tmux", "has-session", "-t", local_session],
        capture_output=True,
    )
    if r.returncode != 0:
        return (
            f"ERROR: Local tmux session '{local_session}' not found. "
            f"Run: tmux new -d -s {local_session}"
        )

    return "Session initialized (single pane, no socket)"


# ──────────────────────────────────────────────
# File Editing (via nvim)
# ──────────────────────────────────────────────


@mcp.tool()
def open_file(path: str) -> str:
    """Open file in nvim. Accepts absolute (~/ or /) or relative (to WORKDIR) paths."""
    full = _resolve_path(path)
    nvim_cmd(f"e {full}")
    return f"Opened {full} in nvim"


@mcp.tool()
def goto_line(n: int) -> str:
    """Jump to line number n in the current nvim buffer."""
    nvim_cmd(str(n))
    return f"Jumped to line {n}"


@mcp.tool()
def replace(old: str, new: str, flags: str = "g") -> str:
    """Substitution in the current nvim buffer. Single-line only.
    For multi-line replacements, use delete_lines() + bulk_insert()."""
    if "\n" not in old and "\n" not in new:
        o = old.replace("/", "\\/")
        n = new.replace("/", "\\/")
        _ensure_nvim()
        _escape_to_normal()
        _local_send_keys("g")
        time.sleep(0.02)
        _local_send_keys("g")
        time.sleep(0.1)
        # Jump to first match
        _local_send_literal(f"/\\V{o}")
        _local_send_keys("Enter")
        time.sleep(0.2)
        # Replace on current line only (no %)
        nvim_cmd(f"s/\\V{o}/{n}/{flags}")
    else:
        first_line = old.split("\n")[0]
        num_lines = old.count("\n") + 1
        _escape_to_normal()
        _local_send_keys("g")
        time.sleep(0.02)
        _local_send_keys("g")
        time.sleep(0.1)
        _local_send_literal(f"/{first_line}")
        _local_send_keys("Enter")
        time.sleep(0.2)
        _local_send_literal(f"{num_lines}dd")
        time.sleep(0.2)
        subprocess.run(
            ["ssh", REMOTE, "cat > ~/tmp/.replace_tmp"],
            input=new + "\n", text=True, check=False,
        )
        _local_send_keys("k")
        time.sleep(0.05)
        nvim_cmd("read ~/tmp/.replace_tmp")
    return f"Replaced '{old[:50]}...' with '{new[:50]}...'"


@mcp.tool()
def delete_lines(start: int, end: int) -> str:
    """Delete a range of lines in the current nvim buffer."""
    nvim_cmd(f"{start},{end}d")
    return f"Deleted lines {start}-{end}"


@mcp.tool()
def insert_after(line: int, text: str) -> str:
    """Insert text after the given line using :read (visible in nvim)."""
    subprocess.run(
        ["ssh", REMOTE, "cat > ~/tmp/.claude_insert"],
        input=text, text=True, check=False,
    )
    nvim_cmd(f"{line}r ~/tmp/.claude_insert")
    return f"Inserted text after line {line}"


@mcp.tool()
def bulk_insert(line: int, text: str) -> str:
    """Insert a large block of text after the given line using :set paste + insert mode.

    WARNING: line=0 is unreliable. Use line >= 1 only.
    To replace the beginning of a file: delete_lines(2, N) to keep line 1,
    then bulk_insert(1, new_text), then delete_lines(1, 1) to remove the old line 1."""
    _ensure_nvim()
    nvim_cmd(str(line))
    time.sleep(0.05)
    nvim_cmd("set paste")
    time.sleep(0.05)
    _local_send_keys("Escape")
    time.sleep(0.05)
    _local_send_keys("o")
    time.sleep(0.05)
    for i, chunk_line in enumerate(text.split("\n")):
        if i > 0:
            _local_send_keys("Enter")
            time.sleep(0.02)
        _local_send_literal(chunk_line)
        time.sleep(0.02)
    time.sleep(0.2)
    _escape_to_normal()
    nvim_cmd("set nopaste")
    return f"Bulk-inserted {len(text.splitlines())} lines after line {line}"


@mcp.tool()
def write_new_file(path: str, content: str) -> str:
    """Create a new file. Accepts absolute (~/ or /) or relative (to WORKDIR) paths."""
    full = _resolve_path(path)
    _ssh(f"mkdir -p $(dirname {full})")
    subprocess.run(
        ["ssh", REMOTE, f"cat > {full}"],
        input=content, text=True, check=False,
    )
    return f"Created new file {full}"


@mcp.tool()
def read_file(path: str, offset: int = 1, limit: int = 300) -> str:
    """Get file contents with pagination. Returns lines offset..offset+limit-1.
    Accepts absolute (~/ or /) or relative (to WORKDIR) paths.
    Args:
        path: File path (absolute or relative to WORKDIR)
        offset: Starting line number (1-based, default 1)
        limit: Number of lines to read (default 300, 0=all)
    """
    full = _resolve_path(path)
    total = _ssh(f"wc -l < {full}").strip()
    if limit == 0:
        result = _ssh(f"cat -n {full}", timeout=60)
    else:
        end = offset + limit - 1
        result = _ssh(
            f"awk 'NR>={offset} && NR<={end} {{printf \"%6d  %s\\n\", NR, $0}}' {full}"
        )
    shown_end = total if limit == 0 else str(min(offset + limit - 1, int(total)))
    return f"{result}\n\n[Lines {offset}-{shown_end} of {total} total]"


# ──────────────────────────────────────────────
# Tab Management (nvim tabs)
# ──────────────────────────────────────────────


@mcp.tool()
def tab_open(path: str) -> str:
    """Open file in a new nvim tab. Accepts absolute (~/ or /) or relative (to WORKDIR) paths."""
    full = _resolve_path(path)
    nvim_cmd(f"tabedit {full}")
    return f"Opened {full} in new nvim tab"


@mcp.tool()
def tab_list() -> str:
    """Get list of open nvim tabs."""
    nvim_cmd("tabs")
    time.sleep(0.2)
    return _local_capture(20)


@mcp.tool()
def tab_switch(n: int) -> str:
    """Switch to the nth nvim tab (1-indexed)."""
    nvim_cmd(f"tabn {n}")
    return f"Switched to tab {n}"


@mcp.tool()
def tab_next() -> str:
    """Switch to the next nvim tab."""
    nvim_cmd("tabnext")
    return "Switched to next tab"


@mcp.tool()
def tab_prev() -> str:
    """Switch to the previous nvim tab."""
    nvim_cmd("tabprev")
    return "Switched to previous tab"


@mcp.tool()
def tab_close() -> str:
    """Close the current nvim tab."""
    nvim_cmd("tabclose")
    return "Closed current tab"


# ──────────────────────────────────────────────
# Diff Reporting
# ──────────────────────────────────────────────


@mcp.tool()
def commit_edit(path: str, summary: str) -> dict:
    """Save file, display colored diff, return diff data."""
    nvim_cmd("w")
    time.sleep(0.1)
    return {"path": path, "summary": summary, "status": "saved"}


# ──────────────────────────────────────────────
# Terminal — Main pane
# ──────────────────────────────────────────────


@mcp.tool()
def run(cmd: str) -> str:
    """Execute a command in the main pane. Auto-closes nvim if open."""
    if _is_nvim_running():
        if not _exit_nvim():
            return "ERROR: Could not close nvim. Use local tmux to force quit (ZQ)."
        time.sleep(0.15)
    send(cmd)
    return f"Sent command: {cmd}"


@mcp.tool()
def run_output(lines: int = 50) -> str:
    """Capture recent output from the main pane."""
    return capture(PANE_MAIN, lines)


@mcp.tool()
def run_busy() -> bool:
    """Check if the main pane is running a foreground process."""
    return is_busy_local()


@mcp.tool()
def run_kill() -> str:
    """Send Ctrl+C to the main pane."""
    send_keys_raw(PANE_MAIN, "C-c")
    return "Sent Ctrl+C to main pane"


# ──────────────────────────────────────────────
# Terminal — Parallel sessions
# ──────────────────────────────────────────────


def _local_pane_state() -> str:
    """Detect the state of the local tmux pane.

    Returns one of:
      "remote_tmux"  — SSH alive, attached to remote tmux session
      "remote_shell" — SSH alive, at remote shell prompt (not in tmux)
      "local_shell"  — at local shell prompt (SSH not running)
    """
    r = subprocess.run(
        ["tmux", "display-message", "-t", LOCAL_PANE, "-p",
         "#{pane_current_command}"],
        capture_output=True, text=True, timeout=5,
    )
    current_cmd = r.stdout.strip()
    if current_cmd != "ssh":
        return "local_shell"
    # SSH is running — check if inside remote tmux via status bar
    output = _local_capture(3)
    if f"Session: {SESSION}" in output:
        return "remote_tmux"
    return "remote_shell"


def _detach_remote():
    """Detach from remote tmux only if currently attached.

    After detach, lands at the remote shell (persistent SSH session).
    If already at remote shell or local shell, handles accordingly.
    """
    state = _local_pane_state()
    if state == "remote_tmux":
        _local_send_keys(REMOTE_TMUX_PREFIX)
        time.sleep(0.2)
        _local_send_keys("d")
        time.sleep(0.5)
    elif state == "local_shell":
        _local_send_literal(f"TERM=xterm-256color ssh -t {REMOTE}")
        _local_send_keys("Enter")
        time.sleep(3)
    # "remote_shell" — already at remote prompt, nothing to do


def _attach_remote():
    """Re-attach to the remote tmux session if not already attached."""
    state = _local_pane_state()
    if state == "remote_tmux":
        return  # already attached
    if state == "remote_shell":
        _local_send_literal(f"tmux attach -t {SESSION}")
        _local_send_keys("Enter")
        time.sleep(0.3)
    elif state == "local_shell":
        _local_send_literal(f"TERM=xterm-256color ssh -t {REMOTE}")
        _local_send_keys("Enter")
        time.sleep(3)
        _local_send_literal(f"tmux attach -t {SESSION}")
        _local_send_keys("Enter")
        time.sleep(0.3)


def _remote_shell_cmd(cmd: str):
    """Run a command on the remote shell via detach -> cmd -> re-attach.

    Checks pane state before detach/attach to avoid command corruption.
    """
    _detach_remote()
    _local_send_literal(cmd)
    _local_send_keys("Enter")
    time.sleep(0.2)
    _attach_remote()


@mcp.tool()
def term_new(name: str) -> str:
    """Create a new remote tmux window for parallel work."""
    _remote_shell_cmd(f"tmux new-window -d -n {name} -c {WORKDIR}")
    return f"Created window '{name}'"


@mcp.tool()
def term_send(name: str, cmd: str) -> str:
    """Send a command to the named remote tmux window."""
    _remote_shell_cmd(
        f"tmux send-keys -t :{name} -l {shlex.quote(cmd)}"
    )
    _remote_shell_cmd(
        f"tmux send-keys -t :{name} Enter"
    )
    return f"Sent command to '{name}': {cmd}"


@mcp.tool()
def term_output(name: str, lines: int = 50) -> str:
    """Capture recent output from the named remote tmux window."""
    _detach_remote()
    _local_send_literal(
        f"tmux capture-pane -t :{name} -p -S -{lines}"
    )
    _local_send_keys("Enter")
    time.sleep(0.3)
    output = _local_capture(lines + 5)
    _attach_remote()
    return output


@mcp.tool()
def term_busy(name: str) -> bool:
    """Check if the named window is running a foreground process."""
    output = term_output(name, 5)
    last = ""
    for line in reversed(output.splitlines()):
        if line.strip():
            last = line.strip()
            break
    return not (last.endswith("$") or last.endswith("%"))


@mcp.tool()
def term_kill(name: str) -> str:
    """Send Ctrl+C to the named window."""
    _remote_shell_cmd(f"tmux send-keys -t :{name} C-c")
    return f"Sent Ctrl+C to '{name}'"


@mcp.tool()
def term_close(name: str) -> str:
    """Kill the named window."""
    _remote_shell_cmd(f"tmux kill-window -t :{name}")
    return f"Killed window '{name}'"


@mcp.tool()
def term_list() -> str:
    """List remote tmux windows."""
    _detach_remote()
    _local_send_literal("tmux list-windows")
    _local_send_keys("Enter")
    time.sleep(0.3)
    output = _local_capture(20)
    _attach_remote()
    return output


# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────

if __name__ == "__main__":
    mcp.run(transport="stdio")
