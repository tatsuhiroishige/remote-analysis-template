---
name: log-notion
description: Log analysis results to Notion — create entries, embed QA plots, standard log structure
---

# Notion Logging

Parent page ID: `2f921411-40f1-806e-8723-ec6ad727900b`

## Create Log Entry

Use `mcp__notion__notion-create-pages`:

```json
{
  "parent": {"page_id": "2f921411-40f1-806e-8723-ec6ad727900b"},
  "pages": [{
    "properties": {"title": "YYYY-MM-DD: <title>"},
    "content": "<markdown content>"
  }]
}
```

## Standard Log Structure

```markdown
## Summary
<Brief description - what was done and why>

## Parameters
| Parameter | Value |
|-----------|-------|
| Macro | `<macro_name>.C` |
| Param file | `<param_file>.json` |
| Files processed | N |
| Beam energy | X GeV |

## Results
| Step | n_total | n_after | Efficiency |
|------|---------|---------|------------|
| Selection | ... | ... | ... |
| Vertex | ... | ... | ... |
| PID | ... | ... | ... |

## Key Findings
- <Physics result 1>
- <Physics result 2>

## Output Files
- ROOT: `root/<filename>.root`
- PDF: `pic/<filename>.pdf`

## Status
COMPLETE / ISSUES / FAILED
```

## Embedding QA Plots in Notion

After uploading QA plots to Discord, update Notion page with image:

```json
{
  "page_id": "<page_id>",
  "command": "insert_content_after",
  "selection_with_ellipsis": "## Status...",
  "new_str": "\n\n## QA Plots\n![<name>](<discord_url>)"
}
```

## Physics-First Structure

Log entries should reflect the analysis workflow:
1. Final State Selection
2. Vertex Cuts
3. PID Cuts
4. Kinematics
5. Signal Extraction

## Notes

- Always include date in title (YYYY-MM-DD)
- Use tables for numerical results
- Include file paths for reproducibility
- Reference related todo files if applicable

## Knowledge References

- [docs/workflow/notion.md](../../docs/workflow/notion.md) — Notion integration details
