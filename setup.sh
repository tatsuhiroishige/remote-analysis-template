#!/bin/bash
# setup.sh — Interactive setup for remote-analysis-template
#
# Configures all placeholder values across the project:
#   - scripts/remote_mcp_server.py
#   - scripts/ifarm_cli.sh
#   - scripts/remote_cli.sh
#   - scripts/local_tmux_init.sh
#   - .claude/CLAUDE.md
#   - .claude/hooks/post-compact-context.sh
#
# Also:
#   - Tests SSH connectivity (supports OTP/2FA servers)
#   - Creates remote tmux session
#   - Creates local tmux session with SSH view pane
#   - Verifies MCP server dependencies (uv, python)
#
# Usage:
#   ./setup.sh          # Interactive setup
#   ./setup.sh --reset  # Restore all files to template defaults

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}ℹ${NC}  $1"; }
ok()    { echo -e "${GREEN}✓${NC}  $1"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
err()   { echo -e "${RED}✗${NC}  $1"; }
ask()   { echo -en "${BOLD}$1${NC}"; }

# ──────────────────────────────────────────────
# --reset: Restore all files to template defaults
# ──────────────────────────────────────────────
if [ "$1" = "--reset" ]; then
    echo ""
    echo -e "${BOLD}Remote Analysis Template — Reset${NC}"
    echo "────────────────────────────────────────────"
    echo ""
    warn "This will:"
    echo "  - Restore all config files to template placeholders"
    echo "  - Kill local tmux session (if exists)"
    echo "  - Optionally kill remote tmux session"
    echo ""
    ask "Continue? [y/N]: "
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
        echo "Aborted."
        exit 0
    fi
    echo ""

    # --- Detect current SSH alias from remote_mcp_server.py ---
    CURRENT_SSH=""
    CURRENT_LOCAL_SESSION=""
    CURRENT_REMOTE_SESSION=""
    if [ -f "$SCRIPT_DIR/scripts/remote_mcp_server.py" ]; then
        CURRENT_SSH=$(grep '^REMOTE = ' "$SCRIPT_DIR/scripts/remote_mcp_server.py" | sed 's/REMOTE = "\(.*\)".*/\1/')
        CURRENT_REMOTE_SESSION=$(grep '^SESSION = ' "$SCRIPT_DIR/scripts/remote_mcp_server.py" | sed 's/SESSION = "\(.*\)".*/\1/')
        CURRENT_LOCAL_SESSION=$(grep '^LOCAL_PANE = ' "$SCRIPT_DIR/scripts/remote_mcp_server.py" | sed 's/LOCAL_PANE = "\(.*\):view.0".*/\1/')
    fi

    # --- Kill local tmux session ---
    if [ -n "$CURRENT_LOCAL_SESSION" ] && tmux has-session -t "$CURRENT_LOCAL_SESSION" 2>/dev/null; then
        tmux kill-session -t "$CURRENT_LOCAL_SESSION" 2>/dev/null
        ok "Killed local tmux session '$CURRENT_LOCAL_SESSION'"
    else
        info "No local tmux session to kill"
    fi

    # --- Optionally kill remote tmux session ---
    if [ -n "$CURRENT_SSH" ] && [ -n "$CURRENT_REMOTE_SESSION" ] && [ "$CURRENT_SSH" != "myserver" ]; then
        ask "Kill remote tmux session '$CURRENT_REMOTE_SESSION' on '$CURRENT_SSH'? [y/N]: "
        read -r KILL_REMOTE
        if [[ "$KILL_REMOTE" =~ ^[Yy] ]]; then
            ssh "$CURRENT_SSH" "tmux kill-session -t $CURRENT_REMOTE_SESSION" 2>/dev/null && \
                ok "Killed remote tmux session '$CURRENT_REMOTE_SESSION'" || \
                warn "Could not kill remote tmux session (may not exist)"
        fi
    fi

    # --- Reset scripts/remote_mcp_server.py ---
    if [ -f "$SCRIPT_DIR/scripts/remote_mcp_server.py" ]; then
        sed -i '' \
            -e 's/^REMOTE = .*/REMOTE = "myserver"                          # SSH alias from ~\/.ssh\/config/' \
            -e 's/^SESSION = .*/SESSION = "claude"                           # Remote tmux session name/' \
            -e 's|^WORKDIR = .*|WORKDIR = "/home/user/analysis"              # Remote working directory|' \
            -e 's/^SETUP_CMD = .*/SETUP_CMD = ""                               # Optional: env setup command (e.g. "source \/opt\/env.sh")/' \
            -e 's/^LOCAL_PANE = .*/LOCAL_PANE = "myserver:view.0"               # <local_session>:<window>.<pane>/' \
            -e 's/^REMOTE_TMUX_PREFIX = .*/REMOTE_TMUX_PREFIX = "C-b"/' \
            "$SCRIPT_DIR/scripts/remote_mcp_server.py"
        ok "Reset scripts/remote_mcp_server.py"
    fi

    # --- Reset scripts/ifarm_cli.sh ---
    if [ -f "$SCRIPT_DIR/scripts/ifarm_cli.sh" ]; then
        sed -i '' \
            -e 's/^REMOTE=.*/REMOTE="myserver"                            # SSH alias from ~\/.ssh\/config/' \
            -e 's/^SESSION=.*/SESSION="claude"                             # Remote tmux session name/' \
            -e 's/^LOCAL_PANE=.*/LOCAL_PANE="myserver:view.0"                 # Local tmux pane (<session>:<window>.<pane>)/' \
            -e 's|^WORKDIR=.*|WORKDIR="/home/user/analysis"                # Remote working directory|' \
            "$SCRIPT_DIR/scripts/ifarm_cli.sh"
        ok "Reset scripts/ifarm_cli.sh"
    fi

    # --- Reset scripts/remote_cli.sh ---
    if [ -f "$SCRIPT_DIR/scripts/remote_cli.sh" ]; then
        sed -i '' \
            -e 's/^REMOTE=.*/REMOTE="myserver"/' \
            -e 's/^SESSION=.*/SESSION="claude"/' \
            -e 's/^LOCAL_PANE=.*/LOCAL_PANE="myserver:view.0"/' \
            -e 's|^WORKDIR=.*|WORKDIR="/home/user/analysis"|' \
            "$SCRIPT_DIR/scripts/remote_cli.sh"
        ok "Reset scripts/remote_cli.sh"
    fi

    # --- Reset scripts/local_tmux_init.sh ---
    if [ -f "$SCRIPT_DIR/scripts/local_tmux_init.sh" ]; then
        cat > "$SCRIPT_DIR/scripts/local_tmux_init.sh" << 'INITEOF'
#!/bin/bash
# Create local tmux session that attaches to remote server tmux
# Usage: ./scripts/local_tmux_init.sh

SESSION="myserver"

tmux has-session -t "$SESSION" 2>/dev/null || \
  tmux new-session -d -s "$SESSION" -n view

tmux send-keys -t "$SESSION:view" "TERM=xterm-256color ssh -t myserver 'tmux attach -t claude'" Enter

echo "Local tmux session '$SESSION' created."
echo "Run: tmux attach -t $SESSION"
INITEOF
        chmod +x "$SCRIPT_DIR/scripts/local_tmux_init.sh"
        ok "Reset scripts/local_tmux_init.sh"
    fi

    # --- Reset .claude/CLAUDE.md ---
    if [ -f "$SCRIPT_DIR/.claude/CLAUDE.md" ]; then
        # Use git to restore the template version
        git -C "$SCRIPT_DIR" checkout HEAD -- .claude/CLAUDE.md 2>/dev/null && \
            ok "Reset .claude/CLAUDE.md (from git)" || \
            warn "Could not reset .claude/CLAUDE.md from git"
    fi

    # --- Reset .claude/hooks/post-compact-context.sh ---
    if [ -f "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh" ]; then
        cat > "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh" << 'HOOKEOF'
#!/bin/bash
# Hook: PreCompact — Re-inject critical context after compaction
# TODO: Edit the message below to match your environment
cat << 'EOF'
{"message": "CONTEXT REMINDER after compaction:\n- Remote: $SSH_ALIAS via MCP remote-server tools\n- WORKDIR: ~/your/analysis/directory/\n- Shell: bash on remote\n- Local tmux: session '$LOCAL_SESSION', pane 0\n- Remote tmux: session '$REMOTE_SESSION'\n- nvim detection: check local pane capture for status bar patterns\n- All file editing on remote via MCP nvim tools\n- Local writable: only todo/ and .claude/"}
EOF
exit 0
HOOKEOF
        chmod +x "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh"
        ok "Reset .claude/hooks/post-compact-context.sh"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}Reset complete!${NC}"
    echo ""
    echo "Run ./setup.sh to reconfigure."
    exit 0
fi

# ──────────────────────────────────────────────
# Collect configuration
# ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}Remote Analysis Template — Setup${NC}"
echo "────────────────────────────────────────────"
echo ""

# SSH alias
ask "SSH alias (from ~/.ssh/config): "
read -r SSH_ALIAS
if [ -z "$SSH_ALIAS" ]; then
    err "SSH alias is required."
    exit 1
fi

# Remote WORKDIR
ask "Remote working directory (e.g. ~/analysis): "
read -r WORKDIR
if [ -z "$WORKDIR" ]; then
    err "WORKDIR is required."
    exit 1
fi

# Remote shell
ask "Remote shell [bash]: "
read -r REMOTE_SHELL
REMOTE_SHELL="${REMOTE_SHELL:-bash}"

# Remote tmux session name
ask "Remote tmux session name [claude]: "
read -r REMOTE_SESSION
REMOTE_SESSION="${REMOTE_SESSION:-claude}"

# Remote tmux prefix key
ask "Remote tmux prefix key [C-b]: "
read -r TMUX_PREFIX
TMUX_PREFIX="${TMUX_PREFIX:-C-b}"

# Local tmux session name (default: same as SSH alias)
ask "Local tmux session name [$SSH_ALIAS]: "
read -r LOCAL_SESSION
LOCAL_SESSION="${LOCAL_SESSION:-$SSH_ALIAS}"

# Derived values
LOCAL_PANE="${LOCAL_SESSION}:view.0"

echo ""
echo "────────────────────────────────────────────"
echo -e "${BOLD}Configuration summary:${NC}"
echo "  SSH alias:          $SSH_ALIAS"
echo "  Remote WORKDIR:     $WORKDIR"
echo "  Remote shell:       $REMOTE_SHELL"
echo "  Remote tmux:        $REMOTE_SESSION"
echo "  Remote tmux prefix: $TMUX_PREFIX"
echo "  Local tmux:         $LOCAL_SESSION"
echo "  Local pane:         $LOCAL_PANE"
echo "────────────────────────────────────────────"
ask "Proceed? [Y/n]: "
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Nn] ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ──────────────────────────────────────────────
# Step 1: SSH connectivity test (OTP support)
# ──────────────────────────────────────────────
info "Testing SSH connection to '$SSH_ALIAS'..."

if ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSH_ALIAS" "echo OK" 2>/dev/null | grep -q OK; then
    ok "SSH connection successful (no OTP needed)."
else
    echo ""
    warn "SSH connection failed with BatchMode."
    warn "This server may require OTP/2FA or password authentication."
    echo ""
    info "Please authenticate manually in the prompt below."
    info "After successful login, type 'exit' to return to setup."
    echo ""
    echo -e "${YELLOW}────── SSH session ──────${NC}"
    ssh "$SSH_ALIAS" || true
    echo -e "${YELLOW}────── End SSH session ──────${NC}"
    echo ""

    # Verify ControlMaster is now active
    if ssh -o ConnectTimeout=5 "$SSH_ALIAS" "echo OK" 2>/dev/null | grep -q OK; then
        ok "SSH ControlMaster connection established."
    else
        err "SSH still failing. Check ~/.ssh/config for ControlMaster settings:"
        echo ""
        echo "  Host $SSH_ALIAS"
        echo "      ControlMaster auto"
        echo "      ControlPath ~/.ssh/sockets/%r@%h-%p"
        echo "      ControlPersist 600"
        echo ""
        echo "  mkdir -p ~/.ssh/sockets"
        echo ""
        ask "Continue anyway? [y/N]: "
        read -r FORCE
        if [[ ! "$FORCE" =~ ^[Yy] ]]; then
            exit 1
        fi
    fi
fi

# ──────────────────────────────────────────────
# Step 2: Check prerequisites
# ──────────────────────────────────────────────
info "Checking prerequisites..."

if command -v uv &>/dev/null; then
    ok "uv found: $(uv --version 2>/dev/null || echo 'installed')"
else
    warn "uv not found. Install with: brew install uv  (or pip install uv)"
    warn "MCP server requires uv to run."
fi

if command -v tmux &>/dev/null; then
    ok "tmux found: $(tmux -V)"
else
    err "tmux not found. Install with: brew install tmux"
    exit 1
fi

# ──────────────────────────────────────────────
# Step 3: Update configuration files
# ──────────────────────────────────────────────
info "Updating configuration files..."

# Expand ~ for sed (WORKDIR might contain ~/)
WORKDIR_ESCAPED=$(echo "$WORKDIR" | sed 's/[&/\]/\\&/g')
SSH_ALIAS_ESCAPED=$(echo "$SSH_ALIAS" | sed 's/[&/\]/\\&/g')
LOCAL_PANE_ESCAPED=$(echo "$LOCAL_PANE" | sed 's/[&/\]/\\&/g')
LOCAL_SESSION_ESCAPED=$(echo "$LOCAL_SESSION" | sed 's/[&/\]/\\&/g')
REMOTE_SESSION_ESCAPED=$(echo "$REMOTE_SESSION" | sed 's/[&/\]/\\&/g')
TMUX_PREFIX_ESCAPED=$(echo "$TMUX_PREFIX" | sed 's/[&/\]/\\&/g')

# --- scripts/remote_mcp_server.py ---
if [ -f "$SCRIPT_DIR/scripts/remote_mcp_server.py" ]; then
    sed -i '' \
        -e "s/^REMOTE = .*/REMOTE = \"$SSH_ALIAS_ESCAPED\"/" \
        -e "s/^SESSION = .*/SESSION = \"$REMOTE_SESSION_ESCAPED\"/" \
        -e "s|^WORKDIR = .*|WORKDIR = \"$(echo "$WORKDIR" | sed 's|~|/home/'$(ssh "$SSH_ALIAS" "whoami" 2>/dev/null || echo "user")'|')\"|" \
        -e "s/^LOCAL_PANE = .*/LOCAL_PANE = \"$LOCAL_PANE_ESCAPED\"/" \
        -e "s/^REMOTE_TMUX_PREFIX = .*/REMOTE_TMUX_PREFIX = \"$TMUX_PREFIX_ESCAPED\"/" \
        "$SCRIPT_DIR/scripts/remote_mcp_server.py"
    ok "Updated scripts/remote_mcp_server.py"
fi

# --- scripts/ifarm_cli.sh ---
if [ -f "$SCRIPT_DIR/scripts/ifarm_cli.sh" ]; then
    sed -i '' \
        -e "s/^REMOTE=.*/REMOTE=\"$SSH_ALIAS_ESCAPED\"/" \
        -e "s/^SESSION=.*/SESSION=\"$REMOTE_SESSION_ESCAPED\"/" \
        -e "s/^LOCAL_PANE=.*/LOCAL_PANE=\"$LOCAL_PANE_ESCAPED\"/" \
        -e "s|^WORKDIR=.*|WORKDIR=\"$WORKDIR_ESCAPED\"|" \
        "$SCRIPT_DIR/scripts/ifarm_cli.sh"
    ok "Updated scripts/ifarm_cli.sh"
fi

# --- scripts/remote_cli.sh (if exists) ---
if [ -f "$SCRIPT_DIR/scripts/remote_cli.sh" ]; then
    sed -i '' \
        -e "s/^REMOTE=.*/REMOTE=\"$SSH_ALIAS_ESCAPED\"/" \
        -e "s/^SESSION=.*/SESSION=\"$REMOTE_SESSION_ESCAPED\"/" \
        -e "s/^LOCAL_PANE=.*/LOCAL_PANE=\"$LOCAL_PANE_ESCAPED\"/" \
        -e "s|^WORKDIR=.*|WORKDIR=\"$WORKDIR_ESCAPED\"|" \
        "$SCRIPT_DIR/scripts/remote_cli.sh"
    ok "Updated scripts/remote_cli.sh"
fi

# --- scripts/local_tmux_init.sh ---
if [ -f "$SCRIPT_DIR/scripts/local_tmux_init.sh" ]; then
    cat > "$SCRIPT_DIR/scripts/local_tmux_init.sh" << INITEOF
#!/bin/bash
# Create local tmux session that attaches to remote server tmux
# Usage: ./scripts/local_tmux_init.sh

SESSION="$LOCAL_SESSION"

tmux has-session -t "\$SESSION" 2>/dev/null || \\
  tmux new-session -d -s "\$SESSION" -n view

tmux send-keys -t "\$SESSION:view" "TERM=xterm-256color ssh -t $SSH_ALIAS 'tmux attach -t $REMOTE_SESSION'" Enter

echo "Local tmux session '\$SESSION' created."
echo "Run: tmux attach -t \$SESSION"
INITEOF
    chmod +x "$SCRIPT_DIR/scripts/local_tmux_init.sh"
    ok "Updated scripts/local_tmux_init.sh"
fi

# --- .claude/CLAUDE.md (Environment table) ---
if [ -f "$SCRIPT_DIR/.claude/CLAUDE.md" ]; then
    sed -i '' \
        -e "s|~/your/analysis/directory/|$WORKDIR_ESCAPED/|g" \
        -e "s|bash (or tcsh, zsh)|$REMOTE_SHELL|" \
        -e "s|\`myserver\` (from ~/.ssh/config)|\`$SSH_ALIAS_ESCAPED\`|" \
        -e "s|\`myserver:view.0\`|\`$LOCAL_PANE_ESCAPED\`|" \
        -e "s|\\\$SSH_ALIAS|$SSH_ALIAS_ESCAPED|g" \
        "$SCRIPT_DIR/.claude/CLAUDE.md"
    ok "Updated .claude/CLAUDE.md"
fi

# --- .claude/hooks/post-compact-context.sh ---
if [ -f "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh" ]; then
    cat > "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh" << HOOKEOF
#!/bin/bash
# Hook: PreCompact — Re-inject critical context after compaction
cat << 'EOF'
{"message": "CONTEXT REMINDER after compaction:\n- Remote: $SSH_ALIAS via MCP remote-server tools\n- WORKDIR: $WORKDIR/\n- Shell: $REMOTE_SHELL on remote\n- Local tmux: session '$LOCAL_SESSION', pane 0\n- Remote tmux: session '$REMOTE_SESSION'\n- nvim detection: check local pane capture for status bar patterns\n- All file editing on remote via MCP nvim tools\n- Local writable: only todo/ and .claude/"}
EOF
exit 0
HOOKEOF
    chmod +x "$SCRIPT_DIR/.claude/hooks/post-compact-context.sh"
    ok "Updated .claude/hooks/post-compact-context.sh"
fi

# ──────────────────────────────────────────────
# Step 4: Create remote WORKDIR and tmux session
# ──────────────────────────────────────────────
info "Setting up remote server..."

# Create WORKDIR directories
ssh "$SSH_ALIAS" "mkdir -p $WORKDIR/{macro,param,root,pic,log} ~/tmp" 2>/dev/null && \
    ok "Created remote directories ($WORKDIR/{macro,param,root,pic,log})" || \
    warn "Could not create remote directories (may already exist)"

# Create remote tmux session
ssh "$SSH_ALIAS" "tmux has-session -t $REMOTE_SESSION 2>/dev/null || tmux new-session -d -s $REMOTE_SESSION -n ide -c $WORKDIR" 2>/dev/null && \
    ok "Remote tmux session '$REMOTE_SESSION' ready" || \
    warn "Could not create remote tmux session"

# ──────────────────────────────────────────────
# Step 5: Create local tmux session
# ──────────────────────────────────────────────
info "Setting up local tmux..."

if tmux has-session -t "$LOCAL_SESSION" 2>/dev/null; then
    ok "Local tmux session '$LOCAL_SESSION' already exists"
else
    bash "$SCRIPT_DIR/scripts/local_tmux_init.sh"
    ok "Created local tmux session '$LOCAL_SESSION'"
fi

# ──────────────────────────────────────────────
# Step 6: Verify
# ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}Verification${NC}"
echo "────────────────────────────────────────────"

# Check remote tmux
if ssh "$SSH_ALIAS" "tmux has-session -t $REMOTE_SESSION" 2>/dev/null; then
    ok "Remote tmux session '$REMOTE_SESSION' exists"
else
    warn "Remote tmux session not found"
fi

# Check local tmux
if tmux has-session -t "$LOCAL_SESSION" 2>/dev/null; then
    ok "Local tmux session '$LOCAL_SESSION' exists"
else
    warn "Local tmux session not found"
fi

# Check uv can run MCP server
if command -v uv &>/dev/null; then
    ok "MCP server ready (run via: uv run scripts/remote_mcp_server.py)"
fi

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start Claude Code:  claude"
echo "  2. Verify connection:  /ifarm-status"
echo "  3. Run first analysis: /start-analysis <description>"
echo ""
echo "To attach to local tmux (watch operations live):"
echo "  tmux attach -t $LOCAL_SESSION"
echo ""
