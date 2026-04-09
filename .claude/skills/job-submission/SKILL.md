---
name: job-submission
description: Batch job workflow — submission, monitoring, and output collection
---

# Batch Job Submission

## Workflow

1. Create/prepare job scripts
2. Submit jobs to batch system
3. Monitor: check status periodically
4. Collect outputs when complete

## Monitoring via MCP Tools

```
# Option 1: Main pane
run("<job-status-command>")
run_output(50)

# Option 2: Parallel session (if main pane is busy)
term_new("jobs")
term_send("jobs", "<job-status-command>")
term_output("jobs", 50)
term_close("jobs")
```

## QA Upload to Discord (Optional)

### PDF -> PNG -> Discord

```bash
# 1. Copy from remote
scp $SSH_ALIAS:$WORKDIR/pic/<file>.pdf ./QA/

# 2. Convert to PNG (macOS)
cd QA/
qlmanage -t -s 1200 -o . <file>.pdf

# 3. Upload via webhook
curl -s -F "file=@<file>.pdf.png" \
  -F "content=<description>" \
  "$(cat config/discord_webhook.txt)" \
  | jq -r '.attachments[0].url'
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `qlmanage` fails | Try `sips -s format png <file>.pdf --out <file>.png` |
| Webhook expired | Get new URL from Discord channel settings |
| File too large | Discord limit is 8MB for webhooks |
