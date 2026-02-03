# start-analysis

Start a new analysis workflow with proper setup and planning.

## Usage
```
/start-analysis <description>
```

## Examples
```
/start-analysis Study acceptance with 10 files
/start-analysis Run efficiency calculation
/start-analysis Compare data and simulation
```

## Workflow

This command initiates the standard analysis flow:

```
1. CHECK      → Verify server/tmux status
2. PLAN       → Create todo list from description
3. APPROVE    → Ask user to confirm todo list
4. EXECUTE    → Run tasks sequentially
5. REPORT     → Summarize results
```

## Instructions

### Step 1: Check Environment

```bash
# Verify SSH connection
ssh $HOST "hostname && echo 'SSH OK'"

# Verify tmux session
ssh $HOST "tmux has-session -t claude 2>/dev/null && echo 'tmux OK' || echo 'No session'"

# Check if ROOT is idle
ssh $HOST "tmux capture-pane -t claude -p | tail -5"
```

If tmux session missing:
```bash
ssh $HOST "tmux new-session -d -s claude"
```

### Step 2: Create Todo List

Based on user's description, create tasks for typical analysis:

**For "Run macro X":**
1. Check current parameter file
2. Run macro via tmux
3. Monitor until completion
4. Fetch output PDF
5. (Optional) Upload QA / Log

**For "Study X with Y files":**
1. Edit parameter file (set file_count)
2. Run study macro
3. Monitor progress
4. Fetch results

### Step 3: Present Todo List

```
I'll start the analysis: "<description>"

Todo list:
1. ☐ Check server/tmux status
2. ☐ [specific task based on description]
3. ☐ [specific task]
4. ☐ Fetch output
5. ☐ [optional: upload/log]

Is this todo list correct? May I proceed?
```

### Step 4: Wait for Approval

**Do NOT proceed until user confirms.**

User responses:
- "Yes" / "Go ahead" / "Proceed" → Start execution
- "No" / "Change X" → Modify todo list, ask again
- "Cancel" → Abort

### Step 5: Execute Tasks

For each task:
1. Mark as `in_progress`
2. Execute the action
3. Report result
4. Mark as `completed`
5. Move to next task

### Step 6: Final Report

```
Analysis complete: "<description>"

Results:
- Events processed: X
- Selection efficiency: Y%
- Output: filename.pdf

Files:
- PDF: output/filename.pdf (downloaded)
- ROOT: $WORKDIR/root/filename.root

Next steps?
- /upload-qa to share results
- /log-notion to create log entry
- /check-root to inspect ROOT file
```

## Parameter Detection

When description includes specifics, auto-detect:

| Description contains | Action |
|---------------------|--------|
| "X files" | Set `file_count: X` in params |
| "all files" | Set `use_all: true` |
| "simulation" | Set `use_sim: true` |
| "data" / "experimental" | Set `use_exp: true` |

## Notes

- Always follows todo-workflow rule (ask before executing)
- Checks environment before starting
- Reports progress at each step
- Provides summary with next actions
