#!/bin/bash
# Start Discord bot for Claude Code integration

cd /Users/<LOCAL_USER>/path/to/remote-analysis/scripts

# Activate virtual environment
source discord_bot_env/bin/activate

# Load token
export DISCORD_BOT_TOKEN=$(cat ../config/discord_bot_token.txt)

# Run bot
python3 discord_bot.py
