# ifarm-status

Check SSH connection and tmux session status.

## Usage
```
/ifarm-status
```

## Instructions

### 1. Check SSH connection

```bash
ssh $HOST "hostname && echo 'SSH OK'"
```

### 2. Check tmux session

```bash
ssh $HOST "tmux has-session -t claude 2>/dev/null && echo 'tmux OK' || echo 'No tmux session'"
```

### 3. Check working directory

```bash
ssh $HOST "ls -la \$WORKDIR && echo 'WORKDIR OK'"
```

### 4. Check ROOT availability

```bash
ssh $HOST "which root && root --version"
```

### 5. Report status

| Check | Status | Action if Failed |
|-------|--------|------------------|
| SSH | OK/FAIL | Check ~/.ssh/config |
| tmux | OK/FAIL | Create session |
| WORKDIR | OK/FAIL | Create directory |
| ROOT | OK/FAIL | Load environment module |

## Create Missing Session

```bash
ssh $HOST "tmux new-session -d -s claude"
```

## Create Missing Directory

```bash
ssh $HOST "mkdir -p \$WORKDIR/{macro,param,root,pic,log}"
```

## Notes

- Replace `$HOST` with your SSH alias from CLAUDE.md
- Replace `$WORKDIR` with your working directory
