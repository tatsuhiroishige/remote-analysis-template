---
name: analysis-workflow
description: Analysis workflow patterns — start, plan, execute, report
---

# Analysis Workflow

## Starting an Analysis

### Standard Workflow

```
1. CHECK      → Verify remote/tmux status (init())
2. PLAN       → Create todo list from description
3. APPROVE    → Ask user to confirm todo list
4. EXECUTE    → Run tasks sequentially
5. REPORT     → Summarize results + notification
```

### Environment Verification

```
init()                                    # Create/restore session
run("hostname && date")                   # Verify connection
run_output(5)                             # Check output
run("ls $WORKDIR/")                       # Check WORKDIR exists
run_output(5)
```

If a process is still running from a previous job (`run_busy()` returns true):
- Report to user
- Ask if they want to wait or kill it (`run_kill()`)

### Typical Task Patterns

**For "Run analysis X":**
1. Check current parameter file
2. Run code via tmux
3. Monitor until completion
4. Fetch output
5. (Optional) Upload QA / Log to Notion

**For "Study X with Y files":**
1. Edit parameter file
2. Run study code
3. Monitor progress
4. Fetch results
5. Review output

**For "Compare X and Y":**
1. Check both input files exist
2. Run comparison code
3. Monitor completion
4. Fetch comparison plots

### Todo List Presentation

```
I'll start the analysis: "<description>"

Todo list:
1. [ ] Check remote/tmux status
2. [ ] [specific task based on description]
3. [ ] [specific task]
4. [ ] Fetch output
5. [ ] [optional: upload/log]

Is this todo list correct? May I proceed?
```

**Do NOT proceed until user confirms.**

User responses:
- "Yes" / "Go ahead" / "Proceed" -> Start execution
- "No" / "Change X" -> Modify todo list, ask again
- "Cancel" -> Abort

### Execution

For each task:
1. Mark as `in_progress`
2. Execute the action
3. Report result
4. Mark as `completed`
5. Move to next task

### Final Report Template

```
Analysis complete: "<description>"

Results:
- Items processed: X
- Key metric: Y
- Output: filename.pdf

Files:
- PDF: pic/filename.pdf
- Data: output/filename.dat

Next steps?
- Upload QA to Discord
- Log to Notion
- Inspect output files
```
