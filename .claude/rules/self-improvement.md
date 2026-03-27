# Self-Improvement Rule

## Lesson Tracking

When you make a mistake that is corrected by the user or discovered during work:

1. **Identify the category**: coding, physics, workflow, or style
2. **Log it** in `docs/lessons/<category>.md`
3. **Increment the count** in the HTML comment at the top
4. **Add a row** to the table with: count, date, mistake description, correction, relevant rule/doc

## Count System

The count in each lesson file tracks cumulative mistakes. This creates accountability:
- Review lessons before starting similar tasks
- If the same mistake appears multiple times, propose a rule update

## When to Log

- User corrects your code or approach
- You discover a wrong assumption mid-task
- A build/run fails due to a pattern you should have known

## When NOT to Log

- First encounter with a genuinely new API or tool
- User changes requirements (not a mistake)
- External failures (SSH drops, server issues)

## Review Protocol

Before starting a task, check if `docs/lessons/` has relevant entries:
- Coding task → check `lessons/coding.md`
- Physics analysis → check `lessons/physics.md`
- Multi-step workflow → check `lessons/workflow.md`

## Post-Task Checkpoint

**After completing any multi-step task**, before reporting to the user:

1. **Lessons**: Review the session for mistakes/corrections. Log any new entries to `docs/lessons/`.
2. **Docs**: If new analysis results were produced, update relevant `docs/analysis/` files (cross-section values, pipeline changes, new macros).
3. **MEMORY.md**: If a new stable pattern was confirmed, update memory.

This checkpoint is mandatory — do not skip it even if the task completed successfully.
