# upload-qa

Upload QA plots to Discord via webhook.

## Usage
```
/upload-qa <filename> [description]
```

## Examples
```
/upload-qa acceptance_study.pdf
/upload-qa results.pdf "Acceptance looks good, ready for review"
```

## Prerequisites

1. Create Discord webhook in your server
2. Save webhook URL to `config/discord_webhook.txt`

## Instructions

### 1. Fetch PDF from remote server

```bash
scp $HOST:\$WORKDIR/pic/<filename> QA/
```

### 2. Convert to PNG (macOS)

```bash
qlmanage -t -s 1200 -o QA/ QA/<filename>
```

This creates `QA/<filename>.png`

For Linux, use ImageMagick:
```bash
convert -density 150 QA/<filename> QA/<filename>.png
```

### 3. Upload to Discord

```bash
curl -F "file=@QA/<filename>.png" \
     -F "content=QA: <description>" \
     "$(cat config/discord_webhook.txt)"
```

### 4. Report to user

- Confirm upload success
- Show Discord channel where posted
- Include description used

## Setup Discord Webhook

1. Go to Discord server settings → Integrations → Webhooks
2. Create new webhook, choose channel
3. Copy webhook URL
4. Save to `config/discord_webhook.txt`

## Notes

- Webhook URL is sensitive, don't commit to git
- PNG conversion required (Discord previews images)
- Default resolution 1200px (adjustable with `-s` flag)
