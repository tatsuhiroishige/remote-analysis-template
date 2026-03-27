---
name: plotting
description: ROOT plotting conventions — histograms, canvases, fitting, PDF output, and QA upload
---

# ROOT Plotting

## Procedure

1. Find CANVAS section in macro (`read_file(path)` to inspect)
2. Identify where to add new page
3. Check if using multi-page pattern `(` `)`
4. Edit with MCP nvim tools: `open_file(path)` → `insert_after(line, text)` → `commit_edit(path, summary)`

## QA Upload to Discord

### Via MCP Discord Tool

```
mcp__discord__send-message(
  channel="phd-analysis",
  server="Research",
  message="## QA: <description>\n<results>"
)
```

### PDF → PNG → Discord (via local tools)

```bash
# 1. Copy from remote server
scp remote-server:$WORKDIR/pic/<file>.pdf /Users/<LOCAL_USER>/path/to/remote-analysis/QA/

# 2. Convert to PNG
cd /Users/<LOCAL_USER>/path/to/remote-analysis/QA
qlmanage -t -s 1200 -o . <file>.pdf

# 3. Upload via webhook
curl -s -F "file=@<file>.pdf.png" \
  "$(cat /Users/<LOCAL_USER>/path/to/remote-analysis/config/discord_webhook.txt)"
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `qlmanage` fails | Try `sips -s format png <file>.pdf --out <file>.png` |
| File too large | Discord limit 8MB for webhooks |
| Webhook expired | Get new URL from Discord channel settings |

## Knowledge References

- [docs/root/plot/canvas.md](../../docs/root/plot/canvas.md) — Canvas, grid, multi-page PDF, draw options
- [docs/root/plot/histograms.md](../../docs/root/plot/histograms.md) — Histogram patterns (1D, 2D, struct-based)
- [docs/root/plot/binnings.md](../../docs/root/plot/binnings.md) — Common variable binnings
- [docs/root/fit/functions.md](../../docs/root/fit/functions.md) — Fit function examples
- [docs/root/fit/options.md](../../docs/root/fit/options.md) — Fit options and procedure
