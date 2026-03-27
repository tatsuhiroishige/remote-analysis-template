---
name: job-submission
description: batch system batch job workflow on remote — submission, monitoring, and output collection
---

# Batch Job Submission (batch system)

## Workflow

1. Create workflow: `batch system create -workflow <name>`
2. Add jobs with resource specs
3. Run: `batch system run -workflow <name>`
4. Monitor: `batch system status -workflow <name>`
5. Collect outputs from `/volatile/`

## Monitoring via MCP Tools

```
# Option 1: Main pane
run("batch system status -workflow <name>")
run_output(50)

# Option 2: Parallel session (if main pane is busy)
term_new("jobs")
term_send("jobs", "batch system status -workflow <name>")
term_output("jobs", 50)
term_close("jobs")
```

## QA Upload to Discord

### PDF → PNG → Discord

```bash
# 1. Copy from remote server
scp remote-server:$WORKDIR/pic/<file>.pdf /Users/<LOCAL_USER>/path/to/remote-analysis/QA/

# 2. Convert to PNG
cd /Users/<LOCAL_USER>/path/to/remote-analysis/QA
qlmanage -t -s 1200 -o . <file>.pdf

# 3. Upload via webhook
curl -s -F "file=@<file>.pdf.png" \
  -F "content=<description>" \
  "$(cat /Users/<LOCAL_USER>/path/to/remote-analysis/config/discord_webhook.txt)" \
  | jq -r '.attachments[0].url'
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `qlmanage` fails | Try `sips -s format png <file>.pdf --out <file>.png` |
| Webhook expired | Get new URL from Discord channel settings |
| File too large | Discord limit is 8MB for webhooks |

## Knowledge References

- [docs/computing/batch system.md](../../docs/computing/batch system.md) — batch system commands, job status codes, common issues
- [docs/computing/storage.md](../../docs/computing/storage.md) — Storage paths and output collection
- [docs/simulation/gemc/running.md](../../docs/simulation/gemc/running.md) — GEMC simulation chain
