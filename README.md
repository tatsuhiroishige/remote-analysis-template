# Remote Analysis System with Claude Code

A framework for controlling ROOT-based physics analysis on remote computing clusters using [Claude Code](https://claude.ai/code) as an AI-powered operator.

## Overview

This system enables you to run particle physics analyses on remote computing clusters through natural language conversation with Claude Code. Instead of manually SSH-ing, writing scripts, and monitoring jobs, you simply describe what you want to analyze and Claude handles the execution.

**Key Concept**: Claude Code acts as a *remote operator*, not a local developer. All source code, data, and computations exist on the remote server. This local repository contains only controller scripts and documentation.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Available Commands](#available-commands)
- [Configuration](#configuration)
- [Directory Structure](#directory-structure)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Remote Server Access

You need SSH access to a computing cluster where your analysis runs.

### 2. SSH Configuration

Configure passwordless SSH access. Add to `~/.ssh/config`:

```
Host myserver
    HostName your-server.example.com
    User your-username
    IdentityFile ~/.ssh/id_rsa
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

Create the sockets directory:
```bash
mkdir -p ~/.ssh/sockets
```

Test the connection:
```bash
ssh myserver "echo 'Connection successful'"
```

### 3. tmux Session on Remote Server

Create a persistent tmux session:

```bash
ssh myserver "tmux new-session -d -s claude"
```

Verify:
```bash
ssh myserver "tmux has-session -t claude && echo 'Session exists'"
```

### 4. Claude Code CLI

Install Claude Code:
```bash
npm install -g @anthropic-ai/claude-code
```

Or via Homebrew:
```bash
brew install claude-code
```

### 5. ROOT Environment on Remote Server

Ensure ROOT is available in your remote environment. Add to your shell config (`.bashrc`, `.cshrc`, etc.):

```bash
source /path/to/root/bin/thisroot.sh
```

---

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/your-username/remote-analysis.git
cd remote-analysis
```

Edit `.claude/CLAUDE.md` to set your:
- SSH host alias
- Working directory path
- tmux session name

### 2. Start Claude Code

```bash
claude
```

### 3. Run your first analysis

```
/run-macro myAnalysis params.json
```

### 4. Check progress

```
/check-tmux
```

### 5. Fetch results

```
/fetch-output results.pdf
```

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
│  │  • Executes skills (commands)                             │  │
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

1. **Persistent Sessions**: tmux keeps your analysis running even if your connection drops
2. **Shell Compatibility**: Handles different shells (bash, tcsh, zsh) via script files
3. **Natural Language**: Describe analyses in plain English
4. **Automated Monitoring**: Claude watches progress and reports results
5. **Integrated Logging**: Results can be sent to Notion/Discord automatically

---

## Available Commands

### Core Analysis Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/run-macro <name> [param]` | Run a ROOT macro | `/run-macro analysis params.json` |
| `/check-tmux [lines]` | View tmux session output | `/check-tmux 50` |
| `/check-root <file> [cmd]` | Inspect ROOT file contents | `/check-root output.root` |
| `/fetch-output <file>` | Download output files | `/fetch-output results.pdf` |
| `/edit-remote <path> <old> <new>` | Edit files on remote server | `/edit-remote macro/test.C "old" "new"` |

### Session Management

| Command | Description | Example |
|---------|-------------|---------|
| `/remote-status` | Check SSH and tmux status | `/remote-status` |
| `/kill-root [method]` | Stop a stuck ROOT session | `/kill-root interrupt` |

### Reporting Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/upload-qa <file> [desc]` | Upload QA plot to Discord | `/upload-qa plot.pdf "Cut study"` |
| `/log-notion <title>` | Create Notion log entry | `/log-notion "Analysis Results"` |

### Natural Language

You can also use natural language:

- "Run the vertex cut study"
- "Check if the analysis is still running"
- "Show me the last 100 lines of output"
- "Download the PDF output"
- "What histograms are in the output file?"

---

## Configuration

### Parameter Files (JSON)

Each macro can have a corresponding parameter file:

```json
{
    "flags": {
        "pdf_flag": true,
        "batch_flag": true
    },
    "data": {
        "input_path": "/path/to/data/",
        "file_count": 10
    },
    "output": {
        "root_name": "analysis_output",
        "pic_name": "analysis_plots"
    },
    "cuts": {
        "pt_min": 0.5,
        "eta_max": 2.5
    }
}
```

### Modifying Parameters Remotely

```bash
/edit-remote param/params.json '"file_count": 10' '"file_count": 100'
```

---

## Directory Structure

### Local (This Repository)

```
remote-analysis/
├── .claude/
│   ├── CLAUDE.md              # Main instructions for Claude (EDIT THIS)
│   ├── rules/
│   │   ├── macro-rules.md     # Coding standards
│   │   └── macro-creation.md  # Macro template guide
│   └── skills/
│       ├── run-macro.md       # /run-macro implementation
│       ├── check-tmux.md      # /check-tmux implementation
│       └── ...                # Other skills
├── config/
│   └── discord_webhook.txt    # Discord webhook (optional)
├── docs/                      # Analysis documentation
├── output/                    # Downloaded outputs
├── QA/                        # Downloaded QA plots
├── scripts/                   # Temporary execution scripts
└── todo/                      # Task tracking
```

### Remote (Your Working Directory)

```
your-workdir/
├── macro/
│   ├── commonFunctions.C      # Shared utility functions
│   ├── commonParams.C         # Global parameters
│   ├── ReadParam.C            # JSON parser
│   └── yourAnalysis.C         # Your analysis macros
├── param/                     # JSON parameter files
├── root/                      # Output ROOT files
├── pic/                       # Output PDF files
└── log/                       # Analysis logs
```

---

## Customization

### 1. Edit CLAUDE.md

The main configuration file is `.claude/CLAUDE.md`. Update these settings:

```markdown
## Environment

| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/working/directory/` |
| **Shell** | bash (or tcsh, zsh) |
| **SSH alias** | `myserver` |
| **tmux session** | `claude` |
```

### 2. Adapt Skills

Edit files in `.claude/skills/` to match your environment:

- Update paths in `run-macro.md`
- Change ROOT command (`root` vs custom wrapper)
- Modify output patterns in `check-tmux.md`

### 3. Add Your Documentation

Add analysis-specific docs in `docs/`:
- Cut definitions
- Physics background
- Histogram naming conventions

### 4. Define Macro Rules

Edit `.claude/rules/macro-rules.md` for your coding standards:
- Naming conventions
- Required includes
- Output format requirements

---

## Troubleshooting

### Connection Issues

**SSH connection fails**
```bash
# Test connectivity
ssh myserver "hostname"

# Regenerate control socket
rm ~/.ssh/sockets/*
ssh myserver "echo 'reconnected'"
```

**tmux session doesn't exist**
```bash
ssh myserver "tmux new-session -d -s claude"
```

### Analysis Issues

**ROOT session stuck**
```bash
# Graceful quit
/kill-root quit

# Force interrupt
/kill-root interrupt

# Kill process
/kill-root force
```

**Shell quoting errors**

Never pass parentheses directly via SSH. The `/run-macro` skill handles this by creating script files.

**Edit not finding text**
- Check exact whitespace (spaces vs tabs)
- Verify the file path is correct
- Read the file first to see current content

### Getting Help

```bash
# List available skills
ls .claude/skills/

# View skill documentation
cat .claude/skills/run-macro.md
```

---

## Integration Options

### Discord (QA Uploads)

1. Create a Discord webhook
2. Save URL to `config/discord_webhook.txt`
3. Use `/upload-qa` to share plots

### Notion (Logging)

1. Set up Notion MCP integration
2. Configure page ID in `CLAUDE.md`
3. Use `/log-notion` to create entries

---

## Writing Macros

### Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Study | `study<Topic>.C` | `studyAcceptance.C` |
| Selection | `select<What>.C` | `selectEvents.C` |
| Calculation | `calc<What>.C` | `calcEfficiency.C` |
| Comparison | `compare<What>.C` | `compareDataMC.C` |

### Minimal Template

```cpp
#ifndef ANALYSIS_C
#define ANALYSIS_C

#include "commonFunctions.C"
#include "commonParams.C"
#include "ReadParam.C"

void analysis(std::string param_file="../param/params.json"){

    // Load parameters
    ReadParam* rp = new ReadParam(param_file);
    rp->ConfigParams();
    rp->PrintParams();

    gROOT->SetBatch(par::batch_flag);
    gBenchmark->Start("timer");

    // Your analysis code here...

    gBenchmark->Show("timer");
}

#endif
```

See `.claude/rules/macro-creation.md` for the complete guide.

---

## License

MIT License - Feel free to adapt for your experiment.

---

## Acknowledgments

- [Claude Code](https://claude.ai/code) by Anthropic
- ROOT Team at CERN
