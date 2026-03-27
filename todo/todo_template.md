# Analysis ToDo Specification (TEMPLATE)

This document defines a standardized task specification format for AI agents
performing physics data analysis via remote operation on remote server.

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
7. Execute each subtask via MCP tools (`run`, `open_file`, `commit_edit`, etc.).
8. Capture output via `run_output()` or `term_output()`.
9. Log results to Notion (if configured).
10. After completing all subtasks, output a **Markdown report** summarizing:
    - Subtask list with status
    - Key figures and tables
    - Final numerical results
    - Short physics interpretation
11. **Send report summary to Discord** using `mcp__discord__send-message`.

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
```
# Edit macro if needed
open_file("macro/<macro_name>.C")
replace("old_value", "new_value")
commit_edit("macro/<macro_name>.C", "Updated parameter")

# Run analysis
run("cd macro && root -l -b -q '<macro>.C(\"../param/<params>.json\")' >& ../log/<output>.log")

# Monitor and check output
run_busy()
run_output(50)
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

## Discord Notification

After completing analysis, send summary to Discord:

```
Channel: phd-analysis
Server: Research
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
- All analysis runs on remote server via MCP tools (`run`, `term_send`).
- Use `run_output()` and `term_output()` to capture results.
- All file editing via MCP nvim tools (`open_file`, `replace`, `commit_edit`).
- Always call `commit_edit()` after every edit to generate diff report.
