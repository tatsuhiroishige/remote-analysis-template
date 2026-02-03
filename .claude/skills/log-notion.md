# log-notion

Create a Notion page to log analysis results.

## Usage
```
/log-notion <title>
```

## Examples
```
/log-notion "Acceptance Study Complete"
/log-notion "2024-01-15: Cross Section Results"
```

## Prerequisites

1. Set up Notion MCP integration with Claude Code
2. Get your parent page ID from Notion
3. Add page ID to `.claude/CLAUDE.md`

## Instructions

### 1. Gather results from recent analysis

Extract from tmux output:
- Event counts
- Efficiency values
- Key numerical results
- Any warnings or notes

### 2. Create Notion page

```
mcp__notion__notion-create-pages
  parent: {"page_id": "YOUR-PAGE-ID"}
  pages: [{
    "properties": {"title": "<title>"},
    "content": "## Summary\n<summary>\n\n## Results\n<results>\n\n## Status\n✓ Complete"
  }]
```

### 3. Standard page format

```markdown
## Summary
Brief description of what was analyzed

## Configuration
- Input: <data source>
- Cuts: <cut summary>
- Output: <output files>

## Results
| Metric | Value |
|--------|-------|
| Events processed | 1,234,567 |
| Selection efficiency | 0.75 |
| Signal yield | 12,345 ± 111 |

## Notes
Any observations or issues

## Status
✓ Complete / ⚠ Needs review / ✗ Failed
```

## Get Page ID

1. Open Notion page in browser
2. URL format: `notion.so/<workspace>/<page-title>-<PAGE-ID>`
3. Copy the 32-character ID at the end

## Notes

- Requires Notion MCP to be configured
- Page ID must be set in CLAUDE.md
- Creates child page under specified parent
