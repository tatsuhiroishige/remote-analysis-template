# run-macro

Run a ROOT macro on the remote server via tmux session.

## Usage
```
/run-macro <macro_name> [param_file]
```

## Examples
```
/run-macro studyAcceptance params_acc.json
/run-macro calcEfficiency params_eff.json
/run-macro analysis
```

## Instructions

### 1. Verify server status first
```bash
ssh $HOST "tmux has-session -t claude 2>/dev/null && echo 'OK' || echo 'No session'"
```
If no session, create one:
```bash
ssh $HOST "tmux new-session -d -s claude"
```

### 2. Create execution script locally
Save to `scripts/run_<macro_name>.sh`:
```bash
#!/bin/bash
cd $WORKDIR/macro
root -b -q '<macro_name>.C("../param/<param_file>")'
```

**Notes:**
- Always `cd` to macro directory first
- Use batch mode (`-b -q`)
- If no param_file, use: `root -b -q '<macro_name>.C'`

### 3. Transfer and execute
```bash
scp scripts/run_<macro_name>.sh $HOST:~/tmp/
ssh $HOST "tmux send-keys -t claude 'bash ~/tmp/run_<macro_name>.sh' Enter"
```

### 4. Monitor progress
```bash
ssh $HOST "tmux capture-pane -t claude -p | tail -30"
```

Look for:
- Progress indicators (e.g., `Processing: X/Y`)
- `root [N]` prompt → ROOT idle, analysis complete

### 5. Exit ROOT when complete
```bash
ssh $HOST "tmux send-keys -t claude '.q' Enter"
```

### 6. Report results
Parse output for standard format:
```
step, n_total, n_after, efficiency
```

## Paths
Replace `$WORKDIR` and `$HOST` with values from CLAUDE.md:
- **Macros**: `$WORKDIR/macro/`
- **Params**: `$WORKDIR/param/`
- **Output ROOT**: `$WORKDIR/root/`
- **Output PDF**: `$WORKDIR/pic/`

## Notes
- All paths in macros are relative to macro directory
- Macros must be independently runnable
