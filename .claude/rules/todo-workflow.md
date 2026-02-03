# Todo List Workflow Rule

## Procedure

When starting a new analysis task or receiving instructions that involve multiple steps:

1. **Create todo list first**
   - Break down the task into clear, actionable items
   - Use `TaskCreate` for each step
   - Include descriptions with acceptance criteria

2. **Present todo list to user**
   - Show the complete list of tasks
   - Explain what each task will accomplish
   - Ask: "Is this todo list correct? May I proceed?"

3. **Wait for approval**
   - Do NOT start executing tasks until user confirms
   - If user requests changes, update the todo list and ask again

4. **Execute after approval**
   - Only proceed after explicit user approval
   - Update task status as you work (`in_progress` → `completed`)

## Example

```
User: "Run the acceptance study and upload results"

Claude: I'll create a todo list for this task:

1. Check server/tmux status
2. Run studyAcceptance macro with current parameters
3. Monitor progress until completion
4. Fetch output PDF to local
5. Upload QA plot to Discord

Is this todo list correct? May I proceed?

User: "Yes, go ahead"

Claude: [Now begins execution]
```

## Why This Rule Exists

- Prevents misunderstanding of user intent
- Allows user to catch mistakes before execution
- Provides clear documentation of planned work
- Saves compute resources by confirming before running
