#!/bin/bash
# Hook: PostToolUse — Remind to commit_edit after nvim editing tools
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only trigger for editing tools (not commit_edit itself, not read-only tools)
case "$TOOL" in
    mcp__remote-server__replace|\
    mcp__remote-server__insert_after|\
    mcp__remote-server__bulk_insert|\
    mcp__remote-server__delete_lines)
        echo '{"message": "Remember to call commit_edit() to save and report the diff."}'
        ;;
esac

exit 0
