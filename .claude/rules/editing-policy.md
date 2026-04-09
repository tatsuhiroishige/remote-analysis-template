---
trigger: always_on
---

# Editing Workflow

All file editing happens on the remote server via MCP `remote-server` tools (primary) or `./scripts/ifarm_cli.sh` (fallback/extras). No local file editing except `todo/` and `.claude/`.

## Tool Reference

### MCP Tools (Primary)

#### Session Management

| Tool | Description |
|------|-------------|
| `init()` | Create/restore remote tmux session (idempotent) |
| `term_list()` | List all tmux windows |

#### File Editing (via nvim)

| Tool | Description |
|------|-------------|
| `open_file(path)` | Open file in nvim (absolute or relative to WORKDIR) |
| `goto_line(n)` | Jump to line number |
| `replace(old, new)` | Single-line substitution only. For 2+ lines use `delete_lines` + `bulk_insert` |
| `delete_lines(start, end)` | Delete line range |
| `insert_after(line, text)` | Insert text after line (via `:read`) |
| `bulk_insert(line, text)` | Insert large block (via `:set paste` + insert mode) |
| `commit_edit(path, summary)` | Save file + report diff |
| `write_new_file(path, content)` | Create new file on remote |
| `read_file(path)` | Get file contents |

#### nvim Tabs

| Tool | Description |
|------|-------------|
| `tab_open(path)` | Open file in new nvim tab |
| `tab_list()` | List open nvim tabs |
| `tab_switch(n)` | Switch to nth tab (1-indexed) |
| `tab_next()` | Next tab |
| `tab_prev()` | Previous tab |
| `tab_close()` | Close current tab |

#### Command Execution (Main Pane)

| Tool | Description |
|------|-------------|
| `run(cmd)` | Send command to main pane (**auto-closes nvim if open**) |
| `run_output(lines)` | Capture main pane output (default 50 lines) |
| `run_busy()` | Check if main pane has running process |
| `run_kill()` | Send Ctrl+C to main pane |

#### Parallel Sessions

| Tool | Description |
|------|-------------|
| `term_new(name)` | Create named tmux window on remote |
| `term_send(name, cmd)` | Send command to named window |
| `term_output(name, lines)` | Capture output from named window |
| `term_busy(name)` | Check if named window is busy |
| `term_kill(name)` | Send Ctrl+C to named window |
| `term_close(name)` | Kill named window |

### CLI Helper: `./scripts/ifarm_cli.sh` (Fallback & Extras)

Features not available in MCP tools:

| Command | Description |
|---------|-------------|
| `findlines <file> '<pattern>'` | Batch grep -- line numbers in one SSH call |
| `vim-view [line]` | Jump to line + capture screen (instant) |
| `vim-pagedown` / `vim-pageup` | Half-page scroll (`C-d` / `C-u`) |
| `vim-top` / `vim-bottom` | Go to top (`gg`) / end (`G`) |
| `vim-replace-save "<old>" "<new>"` | Replace + save in one call |
| `capture-screen` | Capture entire local tmux view |
| `status` | Show what's running in main pane |

## nvim State Safety

- MCP nvim commands auto-send Escape before Ex commands (safe from INSERT mode)
- `run(cmd)` auto-closes nvim before sending shell commands
- **Always close nvim** after editing is done -- either via `run(cmd)` (auto-close) or explicitly
- Before editing, check `run_output()` for `-- INSERT --` if unsure of state

### Mandatory: Save before read_file

**`read_file(path)` reads from disk, NOT from the nvim buffer.** If you have unsaved edits in nvim, `read_file()` will return stale content. Always `commit_edit()` before using `read_file()` to verify content after an edit.

```
# WRONG -- read_file sees old content:
bulk_insert(100, "new code")
read_file("macro/foo.C")       # stale! doesn't include bulk_insert

# CORRECT -- save first:
bulk_insert(100, "new code")
commit_edit("macro/foo.C", "added new code")
read_file("macro/foo.C")       # now sees the new content
```

### Mandatory: Verify after every edit

**Every `replace()`, `delete_lines()`, `insert_after()` must be verified before the next edit.**

```
# Correct pattern:
open_file("macro/foo.C")
replace("old_text", "new_text")
run_output(10)                 # verify edit landed correctly
replace("another_old", "another_new")
run_output(10)                 # verify again
commit_edit("macro/foo.C", "summary")
```

- Chaining multiple edits without verification causes silent file corruption
- **`replace()` is single-line only** -- multi-line regex can corrupt files
- **2+ line block edits**: `delete_lines(start, end)` then `bulk_insert(line, text)`
- **`bulk_insert(line=0)` is forbidden** -- use `line >= 1` only
- `delete_lines()` shifts line numbers -- verify before deleting more

### Mandatory: Close nvim after commit_edit

**`commit_edit()` saves but does NOT close nvim.** After every `commit_edit()`:

1. Close nvim: `run(":q!")` or local tmux `ZQ`
2. Verify shell prompt: `run_output(3)` -- must see `$` prompt
3. Only then proceed to next command

```
# Correct pattern:
commit_edit("macro/foo.C", "summary")
run(":q!")                    # close nvim
run_output(3)                 # verify $ prompt
run("cd macro && ...")        # now safe to run
```

Skipping step 1-2 causes subsequent `run()` to type into nvim buffer, corrupting pane state.

### Local tmux escape hatch

When MCP tools can't escape nvim (stuck in INSERT mode, `run()` types text into buffer):

```bash
# 1. Escape INSERT mode
tmux send-keys -t <local_pane> Escape

# 2. Quit without saving (ZQ = :q!)
tmux send-keys -t <local_pane> 'Z' 'Q'

# 3. Or save and quit (ZZ = :wq)
tmux send-keys -t <local_pane> 'Z' 'Z'
```

**Do NOT use** `tmux send-keys ':q!' Enter` -- the `!` gets escaped by tmux/shell, causing `E488: Trailing characters`. Always use `ZQ` / `ZZ` instead.

## Opening & Editing Files

```
# Open file
open_file("macro/foo.C")

# Substitution
replace("old_text", "new_text")

# Delete lines
delete_lines(42, 50)

# Insert after line
insert_after(30, "// new code\nint x = 42;")

# Save + report
commit_edit("macro/foo.C", "Added variable x")
```

## Efficient Editing Patterns

### Batch Replace

```
open_file("macro/foo.C")
replace("oldName", "newName")
replace("OLD_GUARD", "NEW_GUARD")
commit_edit("macro/foo.C", "Renamed variables")
```

### Large Block Insertion

Use `insert_after()` for multi-line blocks (uses `:read` internally):

```
open_file("macro/foo.C")
insert_after(123, "// New function\nvoid bar() {\n    cout << 1;\n}")
commit_edit("macro/foo.C", "Added bar function")
```

For very large blocks, use `bulk_insert()` (uses `:set paste` + insert mode):

```
open_file("macro/foo.C")
bulk_insert(123, "line1\nline2\nline3\n...")
commit_edit("macro/foo.C", "Inserted large block")
```

### Multi-Point Insertion (bottom-to-top)

When inserting at multiple locations:

1. Use `ifarm_cli.sh findlines` to get all target line numbers in one SSH call
2. Insert from **highest line number first** -- earlier numbers don't shift
3. Use `insert_after(line, text)` for each insertion point
4. Single `commit_edit()` at the end

## After Every Edit: Verify & Report

After editing a file, verify the change:

```
# Re-read via MCP (most reliable)
read_file("macro/foo.C")

# Or check pane content
run_output(50)
```

Report format in chat:
```
"Edited {path}:
 - {change 1}
 - {change 2}"
```

## Macro Editing Policy

### Typical Analysis Structure

ROOT macros follow this standard flow:

```
1. INPUT        → Read data (ROOT/other files)
2. HISTOGRAMS   → Define TH1D, TH2D with explicit binning
3. EVENT LOOP   → Loop with cut conditions, fill histograms
4. POST-LOOP    → Fitting, calculations, normalization
5. CANVAS       → Create canvas, draw histograms
6. OUTPUT       → Save to PDF and ROOT file
```

### Allowed Edits

| Edit | Section | Tools |
|------|---------|-------|
| Add histogram | HISTOGRAMS + LOOP | `open_file` -> `insert_after` -> `commit_edit` |
| Add canvas/PDF page | CANVAS | `open_file` -> `insert_after` -> `commit_edit` |
| Add fitting | POST-LOOP | `open_file` -> `insert_after` -> `commit_edit` |
| Change cut values | LOOP | `open_file` -> `replace` -> `commit_edit` |
| Change parameters | Any | `open_file` -> `replace` -> `commit_edit` |

### Edit Procedure

1. **Explain** what will be added/changed
2. **Show** the code to be inserted
3. **Identify** where in the code (section)
4. **Ask** for approval
5. **Open file**: `open_file(path)`
6. **Execute** edit (`replace`, `insert_after`, `delete_lines`)
7. **Save**: `commit_edit(path, summary)`
8. **Verify**: `read_file(path)` or `run_output()`
9. **Report** changes in chat

### NOT Allowed Without Discussion

- Removing existing code blocks
- Changing core logic or formulas
- Restructuring the code flow
- Deleting functions or classes
