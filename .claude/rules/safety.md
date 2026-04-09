---
trigger: always_on
---

# Safety & Operations Policy

## Architecture

Remote tmux session uses a single pane. Parallel tasks use separate tmux windows.

**MCP `remote-server` tools are the primary interface** for all remote operations (file editing, command execution, session management).
`./scripts/ifarm_cli.sh` is available as fallback and for extra features (`findlines`, `vim-view`, `capture-screen`).

## Allowed Operations

- File editing via MCP nvim tools (`open_file`, `replace`, `insert_after`, `bulk_insert`, `delete_lines`, `commit_edit`)
- File reading via MCP `read_file(path)`
- Command execution via MCP `run(cmd)`, output capture via `run_output(lines)`
- Parallel sessions via MCP `term_new`, `term_send`, `term_output`, `term_close`
- `ifarm_cli.sh` for extras: `findlines`, `vim-view`, `capture-screen`, navigation (`vim-pagedown` etc.)
- `scp` for fetching output files (PDF, ROOT)
- Create/update todo files in local `todo/` directory
- Upload QA plots to Discord, log to Notion (if configured)

## Local File Editing

**Only `todo/` directory and `.claude/` configuration are writable locally.**

- All code editing happens on remote server via MCP nvim tools (or CLI helper as fallback)
- Do NOT edit local files outside `todo/` and `.claude/`

## Forbidden Operations

- Destructive commands on remote: `rm -rf`, `chmod -R`, `chown`
- Analysis software only exists on remote server (never run locally)
- Building or compiling locally
- **Never use `/tmp`** for temporary files — use `~/tmp/` instead (both local and remote)

## Failure Handling

1. Inspect log file first (`run("tail -n 200 ...")` + `run_output()`)
2. Explain technical cause
3. Propose minimal fix
4. Never retry blindly

## Human Responsibilities

Tasks that require human intervention:
- Interactive sessions (debugger, interpreter)
- Large-scale refactoring
- Final judgment on results

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Shell quoting errors | MCP `run(cmd)` sends through local tmux (handles quoting) |
| Analysis process stuck | `run_kill()` or `term_close(name)` |
| nvim in wrong mode | MCP `nvim_cmd` sends Escape first (automatic) |
| SSH connection dropped | ControlMaster auto-reconnects on next SSH call |
| Remote tmux session lost | `init()` recreates session |
| Local tmux session lost | `tmux new -d -s <session>` + attach SSH |

## Global Constraints

- Do not modify existing code without explicit user approval
- Always search for existing files before proposing new ones
- All analysis runs on remote via MCP `run(cmd)` or `term_send(name, cmd)`
- Use `run_output()` and `term_output(name)` to capture results
- All file editing via MCP nvim tools (`open_file`, `replace`, `insert_after`, `commit_edit`)
- Always verify edits after saving (`read_file(path)` or `run_output()`)
- **Always close nvim** (`run(":q!")` or ensure `run()` auto-closes) before running shell commands
