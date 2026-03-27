# Remote Physics Analysis



## Environment

| Item | Value |
|------|-------|
| WORKDIR | `~/<PROJECT_DIR>/` |
| Shell | Remote server uses **<SHELL>** (check your server) |
| Remote tmux | session `claude`, window `ide` (single pane) |
| Local tmux | session `remote-server`, window `view` (pane 0: ssh → remote tmux) |
| Operations | MCP `remote-server` tools (primary), `./scripts/remote_cli.sh` (fallback/extras) |

## Project Structure

| Resource | Path | Description |
|----------|------|-------------|
| Rules | `.claude/rules/` | editing, coding, communication, safety |
| Agents | `.claude/agents/` | build-runner, physics-reviewer, code-explorer, data-inspector |
| Skills | `.claude/skills/` | analysis, remote-ide, data-reading, job-submission, plotting, monte-carlo |
| Docs | [`docs/README.md`](docs/README.md) | Analysis knowledge base (7 domains) |
| Tasks | [`todo/README.md`](todo/README.md) | Analysis logs and task tracking |
| Spec | `docs/claude-code-remote-spec.md` | Full system architecture |
| Notion | Parent page `2f921411-40f1-806e-8723-ec6ad727900b` | Logging |
