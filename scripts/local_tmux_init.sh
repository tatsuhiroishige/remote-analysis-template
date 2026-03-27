#!/bin/bash
# Create local tmux session that attaches to remote server tmux
# Usage: ./scripts/local_tmux_init.sh
#
# Architecture:
#   Local tmux "remote-server" → Window "view", Pane 0
#     └─ ssh -t remote-server "tmux attach -t claude"
#          └─ Remote tmux "claude:ide" (single pane)
#   Parallel tasks use separate tmux sessions

SESSION="remote-server"

tmux has-session -t "$SESSION" 2>/dev/null || \
  tmux new-session -d -s "$SESSION" -n view

tmux send-keys -t "$SESSION:view" "ssh -t remote-server 'tmux attach -t claude'" Enter

echo "Local tmux session '$SESSION' created."
echo "Run: tmux attach -t $SESSION"
