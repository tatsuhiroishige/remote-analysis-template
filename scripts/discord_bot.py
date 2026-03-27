#!/usr/bin/env python3
"""
Discord Bot for Claude Code Integration
Monitors #phd-analysis for @request: messages and processes them via Claude CLI in tmux
INTERACTIVE MODE - Full visibility of Claude's process
"""

import discord
import subprocess
import asyncio
import os
import sys
import time
from datetime import datetime

# Force unbuffered output
sys.stdout.reconfigure(line_buffering=True)

# Configuration
TOKEN_FILE = os.path.expanduser('~/path/to/remote-analysis/config/discord_bot_token.txt')
if os.path.exists(TOKEN_FILE):
    with open(TOKEN_FILE, 'r') as f:
        DISCORD_TOKEN = f.read().strip()
else:
    DISCORD_TOKEN = os.environ.get('DISCORD_BOT_TOKEN', 'YOUR_BOT_TOKEN_HERE')

CHANNEL_NAME = 'phd-analysis'
REQUEST_PREFIX = '@request:'
WEBHOOK_URL_FILE = os.path.expanduser('~/path/to/remote-analysis/config/discord_webhook.txt')
WORKDIR = os.path.expanduser('~/path/to/remote-analysis')
TMUX_SESSION = 'claude-bot'

# Load webhook URL
with open(WEBHOOK_URL_FILE, 'r') as f:
    WEBHOOK_URL = f.read().strip()

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def run_cmd(cmd):
    """Run a shell command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def ensure_tmux_session():
    """Ensure tmux session exists and is ready"""
    check = run_cmd(f"tmux has-session -t {TMUX_SESSION} 2>/dev/null && echo exists")
    if check != "exists":
        # Create new session with shell that stays alive
        run_cmd(f"tmux new-session -d -s {TMUX_SESSION} -c {WORKDIR}")
        time.sleep(0.5)
        log(f"Created tmux session: {TMUX_SESSION}")
    return True

def is_claude_running():
    """Check if Claude is currently running in the tmux session"""
    output = get_tmux_output(20)
    # Check for Claude's UI indicators (not shell prompt ❯)
    # ⏺ is Claude's thinking indicator, ╭─ is Claude's box
    if '⏺' in output or '╭─' in output or 'bypass permissions' in output.lower():
        return True
    return False

def kill_existing_claude():
    """Kill any existing Claude process and ensure clean shell state"""
    # Check if tmux session exists
    check = run_cmd(f"tmux has-session -t {TMUX_SESSION} 2>/dev/null && echo exists")
    if check != "exists":
        log("No existing tmux session")
        return

    # Check if Claude is running
    if is_claude_running():
        log("Claude is running, sending exit commands...")
        # Send Ctrl+C to cancel any running operation
        run_cmd(f"tmux send-keys -t {TMUX_SESSION} C-c")
        time.sleep(0.5)

        # Send /exit to exit Claude
        run_cmd(f"tmux send-keys -t {TMUX_SESSION} /exit Enter")
        time.sleep(1.5)

        # If still running, try Ctrl+C again
        if is_claude_running():
            run_cmd(f"tmux send-keys -t {TMUX_SESSION} C-c")
            time.sleep(0.5)
    else:
        log("Claude not running, just clearing shell")
        # Just send Ctrl+C to clear any partial input
        run_cmd(f"tmux send-keys -t {TMUX_SESSION} C-c")
        time.sleep(0.3)

def send_keys_to_tmux(text):
    """Send text as keystrokes to tmux (handles special characters)"""
    # Use tmux send-keys with literal flag for special characters
    run_cmd(f"tmux send-keys -t {TMUX_SESSION} -l {repr(text)}")

def send_line_to_tmux(line):
    """Send a line of text followed by Enter"""
    # Escape for shell
    escaped = line.replace("'", "'\\''")
    run_cmd(f"tmux send-keys -t {TMUX_SESSION} '{escaped}'")
    run_cmd(f"tmux send-keys -t {TMUX_SESSION} Enter")

def get_tmux_output(lines=200):
    """Capture tmux pane output"""
    return run_cmd(f"tmux capture-pane -t {TMUX_SESSION} -p -S -{lines}")

async def process_request(message, request_text):
    """Process a request using Claude CLI interactively in tmux"""
    log(f"Processing request from {message.author}: {request_text}")

    # Acknowledge receipt
    try:
        await message.add_reaction('⏳')
    except Exception as e:
        log(f"Could not add reaction: {e}")

    try:
        # Ensure tmux session exists
        ensure_tmux_session()

        # Kill any existing Claude process
        kill_existing_claude()
        await asyncio.sleep(1)

        # Build a concise single-line prompt
        # Keep it simple - just the user request with minimal context
        single_prompt = f"[Discord Request] {request_text} | Workflow: 1) Create todo markdown if analysis task 2) Run on remote server via SSH (tmux:claude) 3) Log to Notion 4) Send summary+images to Discord webhook (config/discord_webhook.txt) | WORKDIR: ~/path/to/remote-analysis | remote: ~/<PROJECT_DIR>"

        log(f"Starting Claude in tmux session: {TMUX_SESSION}")
        log(">>> Monitor with: tmux attach -t claude-bot <<<")

        # Start Claude interactively (NO piping - true interactive mode)
        claude_cmd = f'cd {WORKDIR} && claude --dangerously-skip-permissions'
        send_line_to_tmux(claude_cmd)

        # Wait for Claude to start
        await asyncio.sleep(3)

        # Send the prompt using temp file to avoid shell escaping issues
        log("Sending prompt to Claude...")
        import tempfile
        prompt_file = os.path.join(tempfile.gettempdir(), 'claude_prompt.txt')
        with open(prompt_file, 'w') as f:
            f.write(single_prompt)

        # Load into tmux buffer and paste
        run_cmd(f"tmux load-buffer -b prompt {prompt_file}")
        run_cmd(f"tmux paste-buffer -b prompt -t {TMUX_SESSION}")

        # Submit with Enter
        await asyncio.sleep(0.5)
        run_cmd(f"tmux send-keys -t {TMUX_SESSION} Enter")

        # Wait for completion (poll for completion marker or timeout)
        timeout = 300  # 5 minutes
        start_time = time.time()
        last_output = ""
        claude_started = False
        has_response_content = False  # Track if Claude has shown actual work
        stable_count = 0  # Count consecutive polls with same output
        prompt_snippet = request_text[:50]  # To detect if prompt was received

        # Initial wait - give Claude time to receive and start processing prompt
        await asyncio.sleep(5)

        while time.time() - start_time < timeout:
            await asyncio.sleep(3)  # Check every 3 seconds

            # Capture tmux output
            current_output = get_tmux_output(200)

            # Check if Claude has started (look for Claude UI elements)
            if not claude_started:
                if '⏺' in current_output or '╭─' in current_output:
                    claude_started = True
                    log("Claude started processing...")
                    stable_count = 0

            # Check if Claude has produced actual response content
            # Look for response boxes, tool calls, or completion markers
            if not has_response_content:
                # Response indicators: tool panels, response boxes after prompt
                if ('Bash' in current_output and '⎿' in current_output) or \
                   ('Read' in current_output and '⎿' in current_output) or \
                   ('ssh' in current_output.lower() and 'remote-server' in current_output.lower()) or \
                   ('╭─' in current_output and current_output.count('╭─') > 1) or \
                   ('===TASK_COMPLETE===' in current_output):
                    has_response_content = True
                    log("Claude is producing output...")

            # Check for completion markers
            if '===TASK_COMPLETE===' in current_output:
                log("Task completed (found marker)")
                break

            # Check if Claude finished (idle at prompt, no thinking indicator)
            # IMPORTANT: Only check completion if we've seen actual response content
            if claude_started and has_response_content:
                # Get last 300 chars to check current state
                recent = current_output[-300:] if len(current_output) > 300 else current_output

                # Claude is idle if:
                # 1. Shows ❯ prompt (Claude's input prompt)
                # 2. No ⏺ (thinking indicator) in recent output
                # 3. Output has been stable for 2+ checks
                if '❯' in recent and '⏺' not in recent:
                    if current_output == last_output:
                        stable_count += 1
                        if stable_count >= 2:
                            log("Claude finished (idle at prompt)")
                            break
                    else:
                        stable_count = 0
                else:
                    stable_count = 0

                # Also check for shell prompt (Claude exited completely)
                lines = current_output.strip().split('\n')
                if lines:
                    last_line = lines[-1].strip()
                    if last_line.startswith('➜') or (last_line.endswith('$') and '❯' not in recent):
                        log("Claude exited (shell prompt)")
                        break

            last_output = current_output
        else:
            log("Request timed out")
            await message.add_reaction('⏰')
            try:
                await message.remove_reaction('⏳', client.user)
            except:
                pass
            await message.reply("Request timed out (5 min limit). Check `tmux attach -t claude-bot` for status.")
            return

        # Get the final output
        final_output = get_tmux_output(500)

        # Extract response (everything after the prompt)
        response = "Task processed. Check tmux session for full details."

        # Try to find Claude's response in the output
        if 'Discord request from user:' in final_output:
            parts = final_output.split('Discord request from user:')
            if len(parts) > 1:
                response = parts[-1][:1500]  # Get last response, truncate

        # Clean up the response
        response = response.strip()
        if len(response) > 1800:
            response = response[:1800] + "\n... (truncated)"

        if not response or len(response) < 50:
            response = "Task processed. See full output with: `tmux attach -t claude-bot`"

        # Reply in channel
        await message.reply(f"**Done!** Check tmux for full details.\n\nLast output:\n```\n{response[-500:]}\n```")

        try:
            await message.add_reaction('✅')
            await message.remove_reaction('⏳', client.user)
        except:
            pass

        log("Request completed")

    except Exception as e:
        log(f"Error: {e}")
        import traceback
        traceback.print_exc()
        try:
            await message.add_reaction('❌')
            await message.remove_reaction('⏳', client.user)
        except:
            pass
        await message.reply(f"Error: {str(e)[:100]}\nCheck `tmux attach -t claude-bot`")

@client.event
async def on_ready():
    log(f'Bot connected as {client.user}')
    for guild in client.guilds:
        log(f'  - Server: {guild.name}')
        for channel in guild.text_channels:
            if channel.name == CHANNEL_NAME:
                log(f'  - Monitoring channel: #{channel.name}')
    log(f'')
    log(f'Claude runs INTERACTIVELY in tmux - full visibility!')
    log(f'>>> Monitor: tmux attach -t {TMUX_SESSION} <<<')
    log(f'')
    log(f'Waiting for "{REQUEST_PREFIX}" messages...')

@client.event
async def on_message(message):
    # Ignore bot messages
    if message.author.bot:
        return

    # Check if it's in the right channel
    if message.channel.name != CHANNEL_NAME:
        return

    # Check for request prefix
    content = message.content.strip()
    log(f"Message received: {content[:50]}...")

    if content.lower().startswith(REQUEST_PREFIX.lower()):
        request_text = content[len(REQUEST_PREFIX):].strip()
        if request_text:
            await process_request(message, request_text)
        else:
            await message.reply("Please provide a request after `@request:`")

if __name__ == '__main__':
    if DISCORD_TOKEN == 'YOUR_BOT_TOKEN_HERE':
        print("ERROR: Bot token not found", flush=True)
        exit(1)

    # Ensure output directory exists
    os.makedirs(os.path.expanduser('~/path/to/remote-analysis/output'), exist_ok=True)

    log("Starting Discord bot (INTERACTIVE MODE)...")
    log(f"Claude will run in tmux session: {TMUX_SESSION}")
    log("You can watch Claude's full process with: tmux attach -t claude-bot")
    client.run(DISCORD_TOKEN)
