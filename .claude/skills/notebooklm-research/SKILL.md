---
name: notebooklm-research
description: Query NotebookLM for experiment physics research, then update docs/ knowledge base
---

# NotebookLM Research

## Available Notebook

| Field | Value |
|-------|-------|
| Name | <NOTEBOOKLM_NOTEBOOK_NAME> |
| ID | `<NOTEBOOKLM_NOTEBOOK_ID>` |
| Topics | <RESEARCH_TOPICS> |
| Script | `~/.claude/skills/notebooklm/scripts/run.py` |

## Query Execution

```bash
python3 ~/.claude/skills/notebooklm/scripts/run.py \
  --notebook "<NOTEBOOKLM_NOTEBOOK_ID>" \
  --query "<your question>"
```

## Query Patterns

### Physics Questions
- "What are the experiment Forward Detector subsystems and their roles?"
- "How does K+ PID work in experiment using time-of-flight?"
- "What is the <PARTICLE> decay chain in electroproduction?"
- "What systematic uncertainties affect cross section measurements?"

### Detector Questions
- "What is the LTCC pion threshold in experiment?"
- "How does the RICH detector complement FTOF for kaon ID?"
- "What is the experiment Central Detector acceptance?"

### Simulation Questions
- "What event generators are used for experiment <PARTICLE> analysis?"
- "What is the LUND format for GEMC input?"

## Follow-Up Strategy

NotebookLM answers improve with iterative questioning:
1. Start broad: "What are the main systematic uncertainties in experiment?"
2. Narrow down: "How is the acceptance correction uncertainty estimated?"
3. Get specifics: "What is typical acceptance for K+ <PARTICLE> at 6 GeV?"

## Integration with docs/

When NotebookLM provides verified information:
1. Identify the target doc file in `docs/`
2. Write content following the existing doc style (tables, code blocks, concise)
3. Target 20-80 lines per file
4. Cross-reference related docs with relative links

## Rate Limits

- 50 queries per day per notebook
- Group related questions to minimize API calls
- Cache responses for multi-file updates

## Knowledge References

- [docs/README.md](../../docs/README.md) — Full docs index
- [docs/experiment/](../../docs/experiment/) — experiment experiment knowledge
- [docs/analysis/](../../docs/analysis/) — Analysis methods
- [docs/simulation/](../../docs/simulation/) — Monte Carlo chain
