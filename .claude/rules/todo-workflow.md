---
trigger: always_on
---

# Todo List Workflow Rule

## Procedure

When starting a new analysis task or receiving instructions that involve multiple steps:

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

## File Naming

```
todo/YYYY-MM-DD_<descriptive_name>.md
```

Examples:
- `todo/2026-02-03_acceptance_study.md`
- `todo/2026-02-03_efficiency_calculation.md`

## Required Sections

Each todo file must include:

1. **User Task** - The original request
2. **Goal** - Physics/methodological objective
3. **Subtask List** - Checkbox list of all subtasks
4. **Subtask Units** - For each subtask:
   - Implementation Point List (macro, JSON params, variables, outputs, validation)
   - Status (Pending/In Progress/Complete)
   - Results (filled after execution)
5. **Final Report** - Summary table, key figures, numerical results

## Example

```
User: "Run the acceptance study and upload results"

Claude: I'll create a todo file for this task.

[Creates todo/2026-02-03_acceptance_study.md with:]
- User Task: Run acceptance study and upload results
- Goal: Evaluate detector acceptance
- Subtask List:
  - [ ] Check server/tmux status
  - [ ] Run studyAcceptance macro
  - [ ] Fetch output PDF
  - [ ] Upload QA plot to Discord

Is this todo list correct? May I proceed?

User: "Yes, go ahead"

Claude: [Now begins execution, updating status as work progresses]
```

## Why This Rule Exists

- Prevents misunderstanding of user intent
- Allows user to catch mistakes before execution
- Provides persistent documentation of analysis work
- Creates reproducible record with implementation details
