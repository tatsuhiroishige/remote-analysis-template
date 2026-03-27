#!/bin/bash
# Hook: PreCompact — Re-inject critical context after compaction
cat << 'EOF'
{"message": "CONTEXT REMINDER after compaction:\n- Remote: remote server via MCP remote-server tools\n- WORKDIR: ~/<PROJECT_DIR>/\n- Shell: <SHELL> on remote server\n- Local tmux: session 'remote-server', window 'view', pane 0\n- Remote tmux: session 'claude', prefix Ctrl-a\n- nvim detection: check local pane capture for status bar patterns\n- All file editing on remote server via MCP nvim tools\n- Local writable: only todo/ and .claude/"}
EOF
exit 0
