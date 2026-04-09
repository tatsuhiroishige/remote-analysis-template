---
trigger: always_on
---

# Operations Policy

This rule is superseded by `safety.md` for MCP-based operations.
Kept for reference on the legacy SSH-direct workflow.

## Legacy SSH-Direct Workflow

If MCP server is not available, use direct SSH commands:

```bash
# Run command on remote
ssh $HOST "tmux send-keys -t claude '<command>' Enter"

# Capture output
ssh $HOST "tmux capture-pane -t claude -p | tail -30"

# Edit files via script
cat > scripts/patch.sh << 'EOF'
#!/bin/bash
cd $WORKDIR
cp macro/foo.C macro/foo.C.bak
sed -i 's/old/new/g' macro/foo.C
EOF
scp scripts/patch.sh $HOST:~/tmp/
ssh $HOST "bash ~/tmp/patch.sh"
```

## Log-First Principle

Rely on log files, not tmux screen output:
```bash
ssh $HOST "tail -n 200 \$WORKDIR/log/analysis.log"
ssh $HOST "grep -n 'error' \$WORKDIR/log/analysis.log"
```

## See Also

- `.claude/rules/safety.md` — Primary operations policy (MCP-based)
- `.claude/rules/editing-policy.md` — File editing workflow
