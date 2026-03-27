---
name: analysis
description: Analysis patterns — start workflow, run macros, inspect ROOT files, cross section calculation
---

# experiment Analysis Patterns

## Starting an Analysis

### Standard Workflow

```
1. CHECK      → Verify remote server/tmux status (init())
2. PLAN       → Create todo list from description
3. APPROVE    → Ask user to confirm todo list
4. EXECUTE    → Run tasks sequentially
5. REPORT     → Summarize results + Discord notification
```

### Environment Verification

```
init()                                    # Create/restore IDE layout
run("hostname && date")                   # Verify connection
run_output(5)                             # Check output
run("ls $WORKDIR/macro/*.C | wc -l")     # Check macros exist
run_output(5)
```

If ROOT still running from previous job (`run_busy()` returns true):
- Report to user
- Ask if they want to wait or kill it (`run_kill()`)

### Typical Task Patterns

**For "Run macro X":**
1. Check current parameter file
2. Run macro via tmux
3. Monitor until completion
4. Fetch output PDF
5. (Optional) Upload QA / Log to Notion

**For "Study X with Y files":**
1. Edit parameter file (set file_count)
2. Run study macro
3. Monitor progress
4. Fetch results
5. Review output

**For "Compare X and Y":**
1. Check both input files exist
2. Run comparison macro
3. Monitor completion
4. Fetch comparison plots

### Todo List Presentation

```
I'll start the analysis: "<description>"

Todo list:
1. ☐ Check remote server/tmux status
2. ☐ [specific task based on description]
3. ☐ [specific task]
4. ☐ Fetch output
5. ☐ [optional: upload/log]

Is this todo list correct? May I proceed?
```

**Do NOT proceed until user confirms.**

User responses:
- "Yes" / "Go ahead" / "Proceed" → Start execution
- "No" / "Change X" → Modify todo list, ask again
- "Cancel" → Abort

### Execution

For each task:
1. Mark as `in_progress`
2. Execute the action
3. Report result
4. Mark as `completed`
5. Move to next task

### Parameter Auto-Detection

| Description contains | Action |
|---------------------|--------|
| "X files" | Set `file_count: X` in params |
| "all files" | Set `use_all: true` |
| "simulation" | Set `use_sim: true` |
| "experimental" | Set `use_exp: true` |
| "6 GeV" | Set `sixGeV_flag: true` |
| "7 GeV" | Set `sevenGeV_flag: true` |

### Final Report Template

```
Analysis complete: "<description>"

Results:
- Events processed: X
- Selection efficiency: Y%
- Output: filename.pdf

Files:
- PDF: pic/filename.pdf
- ROOT: root/filename.root

Next steps?
- Upload QA to Discord
- Log to Notion
- Inspect ROOT file
```

## Pipeline Macros

One macro per step. Channel selection via JSON parameters.

**Main pipeline** (L1405/L1520):
`studyVertexCut` → `templateFit` → `calcAcptRatio` → `applyAcptCorrection` → `calcXsec`

**Sub-pipeline** (<CHANNEL> validation):
`calc<CHANNEL>Acpt` → `calcXsec` (<CHANNEL> mode)

See [docs/analysis/pipeline.md](../../docs/analysis/pipeline.md) for full I/O table.

## Knowledge References

- [docs/root/plot/histograms.md](../../docs/root/plot/histograms.md) — Histogram patterns
- [docs/root/plot/binnings.md](../../docs/root/plot/binnings.md) — Common variable binnings
- [docs/root/fit/functions.md](../../docs/root/fit/functions.md) — Fit function examples
- [docs/root/fit/options.md](../../docs/root/fit/options.md) — Fit options and procedure
- [docs/root/io/inspection.md](../../docs/root/io/inspection.md) — ROOT file inspection
- [docs/analysis/pipeline.md](../../docs/analysis/pipeline.md) — Cut chain overview
- [docs/analysis/cuts.md](../../docs/analysis/cuts.md) — Cut summary table
- [docs/analysis/cross-section.md](../../docs/analysis/cross-section.md) — Cross section formula

## Related Skills

- [remote-ide](../remote-ide/SKILL.md) — Running macros, file editing, terminal management
- [log-notion](../log-notion/SKILL.md) — Notion logging
- [plotting](../plotting/SKILL.md) — Canvas, PDF output, QA upload
