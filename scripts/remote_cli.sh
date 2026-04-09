#!/bin/bash
# remote_cli.sh v4 — Local-pane unified control
#
# Architecture:
#   All send/capture operations go through LOCAL_PANE.
#   LOCAL_PANE runs SSH into remote server (with or without remote tmux attach).
#   _rtmux is used only for parallel sessions (term-*) and remote-only queries.
#
# Usage: ./scripts/remote_cli.sh <command> [args...]

REMOTE="myserver"
SESSION="claude"
LOCAL_PANE="myserver:view.0"
MAIN="$SESSION:ide.0"
WORKDIR="/home/user/analysis"

# --- Internal: remote tmux command (SSH only, no socket) ---
_rtmux() {
  ssh "$REMOTE" "tmux $(printf '%q ' "$@")" 2>/dev/null | grep -v '^Loading\|WARNING\|requirement'
}

# --- Internal: ensure nvim is running ---
_ensure_nvim() {
  local cmd
  cmd=$(tmux capture-pane -t "$LOCAL_PANE" -p | tail -5)
  # Check if nvim is likely running (no shell prompt visible)
  if echo "$cmd" | grep -q '^\~\|NORMAL\|INSERT\|VISUAL\|-- '; then
    return 0
  fi
  # Check via pane_current_command (local SSH → heuristic)
  local pcmd
  pcmd=$(tmux display-message -t "$LOCAL_PANE" -p '#{pane_current_command}' 2>/dev/null)
  # If local pane runs ssh, we can't check remote command directly
  # Just try sending nvim if no nvim-like output found
  if ! echo "$cmd" | grep -qE '^\s*$|remote-server.*$'; then
    # Something is running (not a shell prompt), assume nvim or similar
    return 0
  fi
  tmux send-keys -t "$LOCAL_PANE" "nvim" Enter
  sleep 1
}

case "$1" in
  # === Setup: verify local pane and SSH connectivity ===
  setup)
    if ! tmux has-session -t "remote-server" 2>/dev/null; then
      echo "Error: local tmux session 'remote-server' not found" >&2; exit 1
    fi
    echo "Local pane command: $(tmux display-message -t "$LOCAL_PANE" -p '#{pane_current_command}' 2>/dev/null)"
    # Quick SSH check
    if ssh -o ConnectTimeout=5 "$REMOTE" "echo OK" 2>/dev/null | grep -q OK; then
      echo "SSH to $REMOTE: OK"
    else
      echo "SSH to $REMOTE: FAILED" >&2; exit 1
    fi
    echo "Ready. All operations go through LOCAL_PANE=$LOCAL_PANE"
    ;;

  # === Status: show what's on the local pane ===
  status)
    echo "--- Local pane ---"
    tmux display-message -t "$LOCAL_PANE" -p '#{pane_current_command}'
    echo "--- Last lines ---"
    tmux capture-pane -t "$LOCAL_PANE" -p | grep -v '^$' | tail -3
    ;;

  # === Send keys (local, instant) ===
  send)
    shift
    tmux send-keys -t "$LOCAL_PANE" "$@"
    ;;
  sendl)
    shift
    tmux send-keys -t "$LOCAL_PANE" -l "$*"
    ;;
  type)
    shift
    tmux send-keys -t "$LOCAL_PANE" -l "$*"
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;

  # === Output capture (all from LOCAL_PANE) ===
  capture|capture-pane|capture-screen)
    lines="${2:-50}"
    tmux capture-pane -t "$LOCAL_PANE" -p -S "-${lines}" | grep -v '^$'
    ;;

  # === Process check: look at last line of local pane ===
  busy)
    # If last non-empty line ends with $ or %, shell is idle
    last=$(tmux capture-pane -t "$LOCAL_PANE" -p | grep -v '^$' | tail -1)
    if echo "$last" | grep -qE '\$\s*$|%\s*$'; then
      echo "idle"
    else
      echo "busy: $last"
    fi
    ;;

  # === Kill (local, instant) ===
  kill)
    tmux send-keys -t "$LOCAL_PANE" C-c
    ;;

  # === vim helpers (auto-start nvim if not running) ===
  vim-open)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.1
    tmux send-keys -t "$LOCAL_PANE" -l ":e $2"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-cmd)
    _ensure_nvim
    shift
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" -l ":$*"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-save)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" -l ":w"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-replace)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" -l ":%s/$2/$3/g"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-replace-save)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" -l ":%s/$2/$3/g"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    sleep 0.1
    tmux send-keys -t "$LOCAL_PANE" -l ":w"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-goto)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" -l ":$2"
    sleep 0.05
    tmux send-keys -t "$LOCAL_PANE" Enter
    ;;
  vim-top)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    tmux send-keys -t "$LOCAL_PANE" "gg"
    ;;
  vim-bottom)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" Escape
    tmux send-keys -t "$LOCAL_PANE" "G"
    ;;
  vim-pagedown)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" C-d
    ;;
  vim-pageup)
    _ensure_nvim
    tmux send-keys -t "$LOCAL_PANE" C-u
    ;;
  vim-view)
    _ensure_nvim
    if [ -n "$2" ]; then
      tmux send-keys -t "$LOCAL_PANE" Escape
      sleep 0.05
      tmux send-keys -t "$LOCAL_PANE" -l ":$2"
      sleep 0.05
      tmux send-keys -t "$LOCAL_PANE" Enter
    fi
    sleep 0.5
    tmux capture-pane -t "$LOCAL_PANE" -p | grep -v '^$'
    ;;

  # === Remote grep (single SSH call, filter module noise) ===
  findlines)
    # Usage: findlines <file> <grep-pattern>
    ssh "$REMOTE" "cd $WORKDIR/macro && grep -n '$3' $2" 2>/dev/null | grep -v '^Loading\|WARNING\|requirement'
    ;;

  # === Parallel sessions ===
  term-new)
    ssh "$REMOTE" "tmux new-session -d -s $2 -c $WORKDIR"
    ;;
  term-send)
    _rtmux send-keys -t "$2:0" -l "$3"
    _rtmux send-keys -t "$2:0" Enter
    ;;
  term-output)
    _rtmux capture-pane -t "$2:0" -p -S "-${3:-50}"
    ;;
  term-busy)
    _rtmux display-message -t "$2:0" -p '#{pane_current_command}'
    ;;
  term-close)
    _rtmux kill-session -t "$2"
    ;;
  term-list)
    ssh "$REMOTE" "tmux list-sessions" 2>/dev/null | grep -v '^Loading\|WARNING\|requirement'
    ;;

  *)
    echo "Unknown command: $1" >&2
    echo "Commands: setup, status, send, sendl, type," >&2
    echo "  capture, capture-pane, capture-screen," >&2
    echo "  busy, kill, vim-open, vim-cmd," >&2
    echo "  vim-save, vim-replace, vim-replace-save, vim-goto, vim-top, vim-bottom," >&2
    echo "  vim-pagedown, vim-pageup, vim-view, findlines," >&2
    echo "  term-new, term-send, term-output, term-busy, term-close, term-list" >&2
    exit 1
    ;;
esac
