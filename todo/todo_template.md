# Analysis ToDo Specification (TEMPLATE)

This document defines a standardized task specification format for AI agents
performing physics data analysis via remote operation.

AI agents must strictly follow the workflow below.

---

## AI Agent Mandatory Workflow

AI agents must:

1. Read **User Task** to understand the request.
2. Summarize the task and decompose it into atomic subtasks.
3. List all subtasks in **Subtask List**.
4. For **each subtask**, create **one subtask unit**.
5. Each subtask unit must include an **Implementation Point List**.
6. Each Implementation Point List must explicitly specify:
   - macro name(s)
   - JSON parameter file
   - variables
   - outputs
   - validation criteria
7. Execute each subtask via SSH/tmux on remote server.
8. Capture output to local `output/` directory.
9. Log results to Notion (if configured).
10. After completing all subtasks, output a **Markdown report** summarizing:
    - Subtask list with status
    - Key figures and tables
    - Final numerical results
    - Short physics interpretation
11. **Send report summary to Discord** (if configured).

---

## Common Format (Must Be Preserved)

### User Task

### Goal

### Subtask List

### One Subtask Unit
- Implementation Point List
  (macro name, JSON params, variables, outputs, validation must be specified)

---

## User Task
<!-- Describe the analysis request in natural language -->

---

## Goal
<!-- Describe the physics or methodological goal -->

---

## Subtask List
<!-- AI agent must list all derived subtasks here -->
- [ ] Subtask 1:
- [ ] Subtask 2:
- [ ] Subtask 3:

---

## One Subtask Unit

### Subtask X: <Subtask Title>

**Status**: [ ] Pending / [ ] In Progress / [ ] Complete

- Implementation Point List:
  - **Macro**:
    - `macro/<macro_name>.C`
  - **JSON Parameters**:
    - `param/params_<name>.json`
  - **Variables**:
    - <!-- variable_1 -->
    - <!-- variable_2 -->
  - **Outputs**:
    - ROOT: `root/<output>.root`
    - PDF: `pic/<output>.pdf`
    - Log: `log/<output>.log`
  - **Validation**:
    - <!-- physical or methodological checks -->

- Execution:
```bash
WORKDIR=~/your/analysis/directory
ssh $HOST "tmux send-keys -t claude 'cd $WORKDIR/macro' Enter"
ssh $HOST "tmux send-keys -t claude 'root -b -q <macro>.C(\"../param/<params>.json\") >& ../log/<output>.log' Enter"
# Wait for completion, then:
ssh $HOST "tmux send-keys -t claude '.q' Enter"
```

- Results:
  - <!-- Summary of key findings -->

---

## One Subtask Unit

### Subtask Y: <Subtask Title>

**Status**: [ ] Pending / [ ] In Progress / [ ] Complete

- Implementation Point List:
  - **Macro**:
    - `macro/<macro_name>.C`
  - **JSON Parameters**:
    - `param/params_<name>.json`
  - **Variables**:
    - <!-- variable_1 -->
  - **Outputs**:
    - ROOT: `root/<output>.root`
    - PDF: `pic/<output>.pdf`
  - **Validation**:
    - <!-- checks -->

- Results:
  - <!-- Summary -->

---

## Final Report

### Summary Table

| Subtask | Status | Key Result |
|---------|--------|------------|
| 1 | | |
| 2 | | |
| 3 | | |

### Key Figures

<!-- Reference output PDFs -->

### Numerical Results

| Quantity | Value | Uncertainty | Unit |
|----------|-------|-------------|------|
| | | | |

### Physics Interpretation

<!-- Concise interpretation of results -->

### Open Questions / Next Steps

-

---

## Discord Notification (Optional)

After completing analysis, send summary to Discord:

```
Channel: your-channel
Server: your-server
```

**Message Format**:
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

---

## Global Constraints

- Do not modify existing macros without explicit user approval.
- Always search for existing macros before proposing new ones.
- All analysis runs on remote server via tmux session "claude".
- Redirect all output to log files (`>& *.log`).
- Capture tmux output locally after each command.
