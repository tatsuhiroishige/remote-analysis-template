# kill-root

Stop a stuck ROOT session in tmux.

## Usage
```
/kill-root [method]
```

Methods: `quit` (default), `interrupt`, `force`

## Examples
```
/kill-root
/kill-root interrupt
/kill-root force
```

## Instructions

### Method 1: quit (graceful)

Send `.q` command to ROOT:

```bash
ssh $HOST "tmux send-keys -t claude '.q' Enter"
```

Wait 5 seconds, then check:
```bash
ssh $HOST "tmux capture-pane -t claude -p | tail -5"
```

### Method 2: interrupt (Ctrl+C)

Send interrupt signal:

```bash
ssh $HOST "tmux send-keys -t claude C-c"
```

If ROOT catches it, may need to send again:
```bash
ssh $HOST "tmux send-keys -t claude C-c"
sleep 2
ssh $HOST "tmux send-keys -t claude '.q' Enter"
```

### Method 3: force (kill process)

Find and kill ROOT process:

```bash
ssh $HOST "pkill -u \$USER root.exe"
```

Or kill by tmux pane:
```bash
ssh $HOST "tmux kill-pane -t claude"
ssh $HOST "tmux new-session -d -s claude"
```

## Decision Tree

1. Try `quit` first (preserves output)
2. If no response after 10s, use `interrupt`
3. If still stuck, use `force`

## After Killing

Verify clean state:
```bash
ssh $HOST "tmux capture-pane -t claude -p | tail -5"
```

Should see shell prompt, not ROOT prompt.

## Notes

- `force` may lose unsaved output
- Always try graceful methods first
- Recreate tmux session if killed
