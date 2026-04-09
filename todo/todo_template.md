# Analysis ToDo Specification (TEMPLATE)

This document defines a standardized task specification format for AI agents
performing analysis via remote operation.

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
   - source file name(s)
   - parameter file
   - variables
   - outputs
   - validation criteria
7. Each subtask unit must include **Concrete Implementation** with exact code diffs, line numbers, and copy-pasteable changes.
8. Execute each subtask via MCP tools on remote server.
9. Capture output to local `output/` directory.
10. Log results to Notion (if configured).
11. After completing all subtasks, output a **Markdown report** summarizing:
    - Subtask list with status
    - Key figures and tables
    - Final numerical results
    - Short interpretation
12. **Send report summary to Discord** (if configured).

---

## Common Format (Must Be Preserved)

### User Task

### Goal

### Subtask List

### One Subtask Unit
- Implementation Point List
  (source file, params, variables, outputs, validation must be specified)
- Concrete Implementation
  (exact code diffs, line numbers, copy-pasteable changes)

---

## User Task
<!-- Describe the analysis request in natural language -->

---

## Goal
<!-- Describe the objective -->

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
  - **Source File**:
    - `macro/<filename>`
  - **Parameters**:
    - `param/<params_file>`
  - **Variables**:
    - <!-- variable_1 -->
    - <!-- variable_2 -->
  - **Outputs**:
    - Data: `root/<output>.root`
    - Plot: `pic/<output>.pdf`
    - Log: `log/<output>.log`
  - **Validation**:
    - <!-- checks -->

- Concrete Implementation:
  <!-- Exact code changes with line numbers. Not abstract descriptions but copy-pasteable diffs. -->
  ```
  # Line 42: Change cut value
  # OLD: if(pt > 0.5)
  # NEW: if(pt > 1.0)

  # After line 100: Add new histogram
  TH1D* h_new = new TH1D("h_new", "Title;X;Counts", 100, 0, 10);
  ```

- Execution:
  ```
  # MCP-based execution
  open_file("macro/<filename>")
  replace("old_text", "new_text")
  commit_edit("macro/<filename>", "description")
  run("cd macro && <run-command>")
  run_output(50)
  ```

- Results:
  - <!-- Summary of key findings -->

---

## One Subtask Unit

### Subtask Y: <Subtask Title>

**Status**: [ ] Pending / [ ] In Progress / [ ] Complete

- Implementation Point List:
  - **Source File**:
    - `macro/<filename>`
  - **Parameters**:
    - `param/<params_file>`
  - **Variables**:
    - <!-- variable_1 -->
  - **Outputs**:
    - Data: `root/<output>.root`
    - Plot: `pic/<output>.pdf`
  - **Validation**:
    - <!-- checks -->

- Concrete Implementation:
  <!-- Exact code changes -->

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

### Interpretation

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

- Do not modify existing code without explicit user approval.
- Always search for existing files before proposing new ones.
- All analysis runs on remote server via MCP `run()` or `term_send()`.
- Use `run_output()` and `term_output()` to capture results.
- All file editing via MCP nvim tools (`open_file`, `replace`, `insert_after`, `commit_edit`).
- Always verify edits after saving (`read_file()` or `run_output()`).
