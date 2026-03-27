# Discord Bot Setup for Claude Code Automation

This bot monitors `#phd-analysis` for `@request:` messages and processes them automatically via Claude CLI.

## Setup Steps

### 1. Install discord.py
```bash
pip install discord.py
```

### 2. Create Discord Bot Token
1. Go to https://discord.com/developers/applications
2. Click **"New Application"** → Name it (e.g., "Claude Analysis Bot")
3. Go to **Bot** section (left sidebar)
4. Click **"Reset Token"** → Copy the token
5. **IMPORTANT**: Enable **"Message Content Intent"** (scroll down, toggle ON)

### 3. Invite Bot to Server
1. Go to **OAuth2 → URL Generator**
2. Select scopes: `bot`
3. Select permissions: `Send Messages`, `Read Message History`, `Add Reactions`
4. Copy the generated URL → Open in browser → Add to "Research" server

### 4. Run the Bot
```bash
cd ~/path/to/remote-analysis/scripts

# Set token (replace with your actual token)
export DISCORD_BOT_TOKEN='your_token_here'

# Run bot
python3 discord_bot.py
```

### 5. Keep Running in Background
```bash
# Option A: Use screen
screen -S discord-bot
python3 discord_bot.py
# Press Ctrl+A, then D to detach

# Option B: Use nohup
nohup python3 discord_bot.py > discord_bot.log 2>&1 &
```

## Usage

Once running, send messages to `#phd-analysis`:
```
@request: check the studyMissXCut output
@request: QA the latest eventMixing PDF
@request: run studyVertexCut with exp20 params
```

The bot will:
1. React with ⏳ (processing)
2. Run Claude CLI with your request
3. Post the response to the channel
4. React with ✅ (done) or ❌ (error)

## Troubleshooting

- **Bot not responding**: Check "Message Content Intent" is enabled
- **Permission errors**: Re-invite bot with correct permissions
- **Claude CLI not found**: Ensure `claude` is in PATH
