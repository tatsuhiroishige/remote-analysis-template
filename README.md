# Remote Analysis Template for Claude Code

A framework for controlling ROOT-based physics analysis on remote computing clusters using [Claude Code](https://claude.ai/code) as an AI-powered operator.

## Overview

This system enables you to run particle physics analyses on remote computing clusters through natural language conversation. Instead of manually SSH-ing, writing scripts, and monitoring jobs, you describe what you want to analyze and Claude handles the execution.

**Key Concept**: Claude Code acts as a *remote operator*, not a local developer. All source code, data, and computations exist on the remote server. This local repository contains only controller scripts and documentation.

## Features

- **Natural Language Control**: Describe analyses in plain English
- **Persistent Sessions**: tmux keeps analyses running even if connection drops
- **Automated Monitoring**: Claude watches progress and reports results
- **File Transfer**: Easy download of ROOT files and PDF plots
- **Remote Editing**: Modify parameters and code on the server
- **Integration**: Optional Discord/Notion logging for QA

---

## Quick Start

### 1. Prerequisites

- SSH access to a remote computing cluster
- ROOT installed on the remote server
- Claude Code CLI installed locally

### 2. Clone this template

```bash
git clone https://github.com/YOUR_USERNAME/remote-analysis-template.git my-analysis
cd my-analysis
```

### 3. Setup SSH

Add to `~/.ssh/config`:

```
Host myserver
    HostName your-server.example.com
    User your-username
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

Create socket directory:
```bash
mkdir -p ~/.ssh/sockets
```

Test connection:
```bash
ssh myserver "echo 'Connection successful'"
```

### 4. Create tmux session on remote server

```bash
ssh myserver "tmux new-session -d -s claude"
```

### 5. Configure for your environment

Edit `.claude/CLAUDE.md`:

```markdown
## Environment

| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/analysis/directory/` |
| **Shell** | bash (or tcsh, zsh) |
| **SSH alias** | `myserver` |
| **tmux session** | `claude` |
```

### 6. Start Claude Code

```bash
claude
```

### 7. Run your first analysis

```
/run-macro myAnalysis params.json
```

Or use natural language:
```
Run the acceptance study macro with default parameters
```

---

## Available Skills (Commands)

### Workflow

| Skill | Description | Example |
|-------|-------------|---------|
| `/start-analysis <desc>` | Start full workflow (plan → approve → run) | `/start-analysis Study acceptance with 10 files` |

### Core Analysis

| Skill | Description | Example |
|-------|-------------|---------|
| `/run-macro <name> [param]` | Run ROOT macro via tmux | `/run-macro analysis params.json` |
| `/check-tmux [lines]` | View tmux session output | `/check-tmux 50` |
| `/check-root <file> [cmd]` | Inspect ROOT file contents | `/check-root output.root` |
| `/fetch-output <file>` | Download output files | `/fetch-output results.pdf` |

### Remote Editing

| Skill | Description | Example |
|-------|-------------|---------|
| `/edit-ifarm <path> <old> <new>` | Edit files on server | `/edit-ifarm macro/cut.C "pt>0.5" "pt>1.0"` |

### Session Management

| Skill | Description | Example |
|-------|-------------|---------|
| `/ifarm-status` | Check SSH and tmux status | `/ifarm-status` |
| `/kill-root [method]` | Stop stuck ROOT session | `/kill-root interrupt` |

### Reporting (Optional)

| Skill | Description | Example |
|-------|-------------|---------|
| `/upload-qa <file> [desc]` | Upload plot to Discord | `/upload-qa plot.pdf "QA check"` |
| `/log-notion <title>` | Create Notion log entry | `/log-notion "Analysis complete"` |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Local Machine                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      Claude Code CLI                       │  │
│  │                                                            │  │
│  │  • Natural language interface                              │  │
│  │  • Reads CLAUDE.md for context                            │  │
│  │  • Executes skills                                        │  │
│  │  • Manages file transfers                                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                         SSH / SCP                                │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Remote Server                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   tmux session: claude                     │  │
│  │                                                            │  │
│  │  • Runs ROOT macros                                       │  │
│  │  • Processes data files                                   │  │
│  │  • Generates output (ROOT, PDF)                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Working Directory:                                              │
│  ├── macro/    ← ROOT analysis macros                           │
│  ├── param/    ← JSON configuration files                       │
│  ├── root/     ← Output ROOT files                              │
│  ├── pic/      ← Output PDF plots                               │
│  └── log/      ← Analysis logs                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

1. **Persistent Sessions**: tmux keeps your analysis running even if your local connection drops
2. **Shell Compatibility**: Script files handle quoting issues across bash/tcsh/zsh
3. **Natural Language**: Describe what you want instead of remembering commands
4. **Automated Monitoring**: Claude watches progress and reports results

---

## Directory Structure

### Local (This Repository)

```
my-analysis/
├── .claude/
│   ├── CLAUDE.md              # Main configuration ← EDIT THIS
│   ├── rules/
│   │   ├── macro-rules.md     # Coding standards
│   │   └── macro-creation.md  # Macro template guide
│   └── skills/
│       ├── run-macro.md       # /run-macro implementation
│       ├── check-tmux.md      # /check-tmux implementation
│       └── ...                # Other skills
├── config/
│   └── discord_webhook.txt    # Discord webhook (optional)
├── docs/                      # Your analysis documentation
├── output/                    # Downloaded tmux outputs
├── QA/                        # Downloaded QA plots
├── scripts/                   # Temporary execution scripts
└── todo/                      # Task tracking
```

### Remote (Your Working Directory)

Set up on your remote server:

```bash
ssh myserver "mkdir -p ~/analysis/{macro,param,root,pic,log}"
```

```
~/analysis/
├── macro/
│   ├── commonFunctions.C      # Shared utility functions
│   ├── commonParams.C         # Global parameters
│   ├── ReadParam.C            # JSON parser (optional)
│   └── yourAnalysis.C         # Your analysis macros
├── param/                     # JSON parameter files
├── root/                      # Output ROOT files
├── pic/                       # Output PDF files
└── log/                       # Analysis logs
```

---

## Configuration Guide

### Step 1: Edit CLAUDE.md

The main file Claude reads is `.claude/CLAUDE.md`. Update these sections:

**Environment**:
```markdown
| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/working/directory/` |
| **Shell** | bash |
| **SSH alias** | `myserver` |
| **tmux session** | `claude` |
```

**Paths**: Update all path references to match your setup.

### Step 2: Adapt Skills (Optional)

Edit files in `.claude/skills/` if needed:

- Change ROOT command (`root` vs `clas12root` vs custom)
- Update path variables
- Modify output patterns

### Step 3: Add Your Documentation

See `docs/analysis_guide.md` for a comprehensive guide on:
- Cut flow patterns
- Background estimation techniques
- Signal extraction methods
- Systematic uncertainties

Create additional docs in `docs/` for:
- Your specific cut definitions
- Physics background
- Histogram naming conventions

---

## Writing Macros

### Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Study | `study<Topic>.C` | `studyAcceptance.C` |
| Selection | `select<What>.C` | `selectGoodEvents.C` |
| Calculation | `calc<What>.C` | `calcEfficiency.C` |
| Comparison | `compare<What>.C` | `compareDataMC.C` |

### Minimal Template

```cpp
#ifndef ANALYSIS_C
#define ANALYSIS_C

void analysis(std::string param_file="../param/params.json"){

    gROOT->SetBatch(true);  // Required for remote execution
    gBenchmark->Start("timer");

    // Your analysis code here...
    TH1D* h_pt = new TH1D("h_pt", "p_{T};p_{T} [GeV/c];Counts", 100, 0, 10);

    // Event loop...

    // Output
    TCanvas* c1 = new TCanvas("c1", "Results", 1200, 800);
    h_pt->Draw();
    c1->Print("../pic/analysis_output.pdf");

    gBenchmark->Show("timer");
}

#endif
```

### Key Rules

1. **Use batch mode**: `gROOT->SetBatch(true)` for remote execution
2. **Run from macro directory**: All paths relative to `macro/`
3. **Explicit binning**: Never rely on ROOT defaults
4. **Print results**: Use CSV-like format for easy parsing

See `.claude/rules/macro-creation.md` for the complete guide.

---

## Example Workflow

```bash
# Start Claude Code in your analysis directory
cd my-analysis
claude

# Run an analysis
> /run-macro studyAcceptance params_acc.json

# Check if it's still running
> /check-tmux

# See more output history
> /check-tmux 100

# Download results when complete
> /fetch-output acceptance_study.pdf

# Share a QA plot (if Discord configured)
> /upload-qa acceptance_study.pdf "Acceptance looks good"
```

---

## Troubleshooting

### Connection Issues

**SSH connection fails**
```bash
# Test basic connectivity
ssh myserver "hostname"

# Regenerate control socket
rm -rf ~/.ssh/sockets/*
ssh myserver "echo 'reconnected'"
```

**tmux session doesn't exist**
```bash
ssh myserver "tmux new-session -d -s claude"
ssh myserver "tmux list-sessions"  # Verify
```

### Analysis Issues

**ROOT session stuck**
```bash
# Try graceful quit
/kill-root quit

# Force interrupt (Ctrl+C equivalent)
/kill-root interrupt

# Kill ROOT process
/kill-root force
```

**Shell quoting errors**

The skills use script files to avoid quoting issues. If you see errors with parentheses or quotes, make sure you're using the skills rather than raw SSH commands.

**Edit not finding text**
- Check exact whitespace (spaces vs tabs)
- Verify newlines match
- Read the file first to see current content

---

## Optional Integrations

### Discord (QA Uploads)

1. Create a Discord webhook in your server
2. Save URL to `config/discord_webhook.txt`
3. Use `/upload-qa` to share plots with your team

### Notion (Logging)

1. Set up Notion MCP integration with Claude Code
2. Add your page ID to `.claude/CLAUDE.md`
3. Use `/log-notion` to create analysis log entries

---

## Requirements

- macOS or Linux (local machine)
- Node.js 18+ (for Claude Code CLI)
- SSH access to remote computing cluster
- ROOT installed on remote server
- tmux on remote server

## Installation

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Or via Homebrew (macOS)
brew install claude-code
```

---

## License

MIT License - Feel free to adapt for your experiment.

---

## Acknowledgments

- [Claude Code](https://claude.ai/code) by Anthropic
- [ROOT](https://root.cern/) by CERN
