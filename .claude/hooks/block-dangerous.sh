#!/bin/bash
# Hook: PreToolUse — Block dangerous commands on remote server
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
CMD=""

if [ "$TOOL" = "mcp__remote-server__run" ] || [ "$TOOL" = "mcp__remote-server__term_send" ]; then
    CMD=$(echo "$INPUT" | jq -r '.tool_input.cmd // empty')
fi

if [ -z "$CMD" ]; then
    exit 0
fi

# Block destructive commands
if echo "$CMD" | grep -qE 'rm\s+(-rf|-fr)\s' ; then
    echo "BLOCKED: rm -rf is forbidden on remote server" >&2
    exit 2
fi

if echo "$CMD" | grep -qE 'chmod\s+-R\s' ; then
    echo "BLOCKED: chmod -R is forbidden on remote server" >&2
    exit 2
fi

if echo "$CMD" | grep -qE 'chown\s' ; then
    echo "BLOCKED: chown is forbidden on remote server" >&2
    exit 2
fi

if echo "$CMD" | grep -qE 'mkfs|dd\s+if=' ; then
    echo "BLOCKED: disk operations are forbidden" >&2
    exit 2
fi

exit 0
