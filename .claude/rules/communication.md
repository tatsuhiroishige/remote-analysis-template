---
trigger: always_on
---

# Communication & Workflow

## Todo Workflow

**Before any multi-step task:** Create todo → Present → **Ask approval** → Execute

### Procedure

1. **Create todo markdown file**
   - Create `todo/YYYY-MM-DD_<task_name>.md` based on `todo/todo_template.md`
   - Fill in User Task, Goal, and Subtask List sections
   - Create Implementation Point List for each subtask

2. **Present todo list to user**
   - Show the subtask list with implementation details
   - Explain what each subtask will accomplish
   - Ask: "Is this todo list correct? May I proceed?"

3. **Wait for approval**
   - Do NOT start executing tasks until user confirms
   - If user requests changes, update the todo file and ask again

4. **Execute after approval**
   - Only proceed after explicit user approval
   - Update subtask status in the markdown file as you work
   - Fill in Results section after each subtask completes

### Required Sections in Todo Files

1. **User Task** — The original request
2. **Goal** — Physics/methodological objective
3. **Subtask List** — Checkbox list of all subtasks
4. **Subtask Units** — For each subtask:
   - Implementation Point List (macro, JSON params, variables, outputs, validation)
   - Status (Pending/In Progress/Complete)
   - Results (filled after execution)
5. **Final Report** — Summary table, key figures, numerical results

### File Naming

```
todo/YYYY-MM-DD_<descriptive_name>.md
```

## Discord Notification

After completing analysis, send summary to Discord:

- **Channel**: `phd-analysis`
- **Server**: `Research`
- **Tool**: `mcp__discord__send-message`

### Message Format

```markdown
## Analysis Complete: <Task Title>

**Date**: YYYY-MM-DD
**Status**: Complete / Partial / Failed

### Summary
- Subtask 1: [status] - [one-line result]
- Subtask 2: [status] - [one-line result]

### Key Results
| Quantity | Value |
|----------|-------|
| ... | ... |

### Next Steps
- ...

Full report: `todo/<filename>.md`
```

## Notion Logging

Parent page ID: `2f921411-40f1-806e-8723-ec6ad727900b`

### Standard Log Structure

```markdown
## Summary
<Brief description>

## Parameters
| Parameter | Value |
|-----------|-------|
| Macro | `<macro_name>.C` |
| Param file | `<param_file>.json` |

## Results
| Step | n_total | n_after | Efficiency |
|------|---------|---------|------------|

## Key Findings
- <Physics result>

## Output Files
- ROOT: `root/<filename>.root`
- PDF: `pic/<filename>.pdf`

## Status
COMPLETE / ISSUES / FAILED
```

## Post-Execution: PDF Retrieval & Upload

After running a macro that produces a PDF:

1. **Fetch PDF** from remote server via scp to local `~/tmp/`
   ```bash
   scp remote-server:$WORKDIR/pic/<output>.pdf ~/tmp/
   ```
2. **Move PDF** to local `output/` directory
   ```bash
   mv ~/tmp/<output>.pdf output/
   ```
3. **Display PDF** in chat using the `Read` tool so the user can review
4. **Send to Discord** (`phd-analysis` channel) with results summary
5. **Log to Notion** (parent page `2f921411-40f1-806e-8723-ec6ad727900b`) with standard log structure

This ensures every analysis result is archived locally, visible in chat, and logged to both Discord and Notion.

## Diff Reporting

After every file edit, call `commit_edit(path, summary)` which:
1. Saves the file in nvim
2. Generates unified diff from pre-edit snapshot
3. Displays colored diff in the terminal pane (visible to human)
4. Returns diff data for chat report

## Log-First Principle

Rely on log files, not tmux screen output:
```
run("tail -n 200 $WORKDIR/log/analysis.log")
run_output(50)

run("grep -n 'error' $WORKDIR/log/analysis.log")
run_output(50)
```
