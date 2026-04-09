#!/bin/bash
# Create local tmux session that attaches to remote server tmux
# Usage: ./scripts/local_tmux_init.sh

SESSION="myserver"

tmux has-session -t "$SESSION" 2>/dev/null || \
  tmux new-session -d -s "$SESSION" -n view

tmux send-keys -t "$SESSION:view" "TERM=xterm-256color ssh -t myserver 'tmux attach -t claude'" Enter

echo "Local tmux session '$SESSION' created."
echo "Run: tmux attach -t $SESSION"
