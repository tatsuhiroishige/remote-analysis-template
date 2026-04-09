#!/bin/bash
# Hook: PreCompact — Re-inject critical context after compaction
# TODO: Edit the message below to match your environment
cat << 'EOF'
{"message": "CONTEXT REMINDER after compaction:\n- Remote: $SSH_ALIAS via MCP remote-server tools\n- WORKDIR: ~/your/analysis/directory/\n- Shell: bash on remote\n- Local tmux: session '$LOCAL_SESSION', pane 0\n- Remote tmux: session '$REMOTE_SESSION'\n- nvim detection: check local pane capture for status bar patterns\n- All file editing on remote via MCP nvim tools\n- Local writable: only todo/ and .claude/"}
EOF
exit 0
