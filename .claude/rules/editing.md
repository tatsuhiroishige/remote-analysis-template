---
trigger: always_on
---

# Editing Workflow

All file editing happens on remote server via MCP `remote-server` tools (primary) or `./scripts/remote_cli.sh` (fallback/extras). No local file editing except `todo/` and `.claude/`.

## Tool Reference

### MCP Tools (Primary)

#### Session Management

| Tool | Description |
|------|-------------|
| `init()` | Create/restore remote tmux session (idempotent) |
| `term_list()` | List all tmux sessions |

#### File Editing (via nvim)

| Tool | Description |
|------|-------------|
| `open_file(path)` | Open file in nvim (absolute or relative to WORKDIR) |
| `goto_line(n)` | Jump to line number |
| `replace(old, new)` | Global substitution `:%s/old/new/g` |
| `delete_lines(start, end)` | Delete line range |
| `insert_after(line, text)` | Insert text after line (via `:read`) |
| `bulk_insert(line, text)` | Insert large block (via `:set paste` + insert mode) |
| `commit_edit(path, summary)` | Save file + report diff |
| `write_new_file(path, content)` | Create new file on remote server |
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
| `term_new(name)` | Create named tmux session on remote |
| `term_send(name, cmd)` | Send command to named session |
| `term_output(name, lines)` | Capture output from named session |
| `term_busy(name)` | Check if named session is busy |
| `term_kill(name)` | Send Ctrl+C to named session |
| `term_close(name)` | Kill named session |

### CLI Helper: `./scripts/remote_cli.sh` (Fallback & Extras)

Features not available in MCP tools:

| Command | Description |
|---------|-------------|
| `findlines <file> '<pattern>'` | Batch grep — line numbers in one SSH call |
| `vim-view [line]` | Jump to line + capture screen (instant) |
| `vim-pagedown` / `vim-pageup` | Half-page scroll (`C-d` / `C-u`) |
| `vim-top` / `vim-bottom` | Go to top (`gg`) / end (`G`) |
| `vim-replace-save "<old>" "<new>"` | Replace + save in one call |
| `capture-screen` | Capture entire local tmux view |
| `status` | Show what's running in main pane |

## nvim State Safety

- MCP nvim commands auto-send Escape before Ex commands (safe from INSERT mode)
- `run(cmd)` auto-closes nvim before sending shell commands
- **Always close nvim** after editing is done — either via `run(cmd)` (auto-close) or explicitly
- Before editing, check `run_output()` for `-- INSERT --` if unsure of state

### Local tmux escape hatch

When MCP tools can't escape nvim (e.g. stuck in INSERT mode, `run()` types text into buffer):

```bash
# 1. Escape INSERT mode
tmux send-keys -t remote-server:view.0 Escape

# 2. Quit without saving (ZQ = :q!)
tmux send-keys -t remote-server:view.0 'Z' 'Q'

# 3. Or save and quit (ZZ = :wq)
tmux send-keys -t remote-server:view.0 'Z' 'Z'
```

**Do NOT use** `tmux send-keys ':q!' Enter` — the `!` gets escaped by tmux/shell, causing `E488: Trailing characters`. Always use `ZQ` / `ZZ` instead.

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

1. Use `remote_cli.sh findlines` to get all target line numbers in one SSH call
2. Insert from **highest line number first** — earlier numbers don't shift
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

## Running Analysis

```
# 1. Open and edit macro if needed
open_file("macro/macroName.C")
replace("old_cut", "new_cut")
commit_edit("macro/macroName.C", "Updated cut value")

# 2. Run macro (run() auto-closes nvim)
run("cd macro && root -l -b -q 'macroName.C(\"../param/params.json\")'")

# 3. Monitor progress
run_busy()          # Check if still running
run_output(50)      # See output
```

For parallel tasks, use separate sessions:

```
term_new("root")
term_send("root", "cd macro && root -l -b -q 'study.C(\"../param/p.json\")'")
term_output("root", 50)
term_close("root")
```

## Macro Editing Policy

### Typical Analysis Structure

ROOT macros follow this standard flow:

```
1. INPUT        → Read data (data/ROOT files)
2. HISTOGRAMS   → Define TH1D, TH2D with explicit binning
3. EVENT LOOP   → Loop with cut conditions, fill histograms
4. POST-LOOP    → Fitting, calculations, normalization
5. CANVAS       → Create canvas, draw histograms
6. OUTPUT       → Save to PDF and ROOT file
```

### Allowed Edits

| Edit | Section | Tools |
|------|---------|-------|
| Add histogram | HISTOGRAMS + LOOP | `open_file` → `insert_after` → `commit_edit` |
| Add canvas/PDF page | CANVAS | `open_file` → `insert_after` → `commit_edit` |
| Add fitting | POST-LOOP | `open_file` → `insert_after` → `commit_edit` |
| Change cut values | LOOP | `open_file` → `replace` → `commit_edit` |
| Change parameters | Any | `open_file` → `replace` → `commit_edit` |

### Edit Procedure

1. **Explain** what will be added/changed
2. **Show** the code to be inserted
3. **Identify** where in the macro (section: HISTOGRAMS, LOOP, POST-LOOP, CANVAS)
4. **Ask** for approval
5. **Open file**: `open_file(path)`
6. **Execute** edit (`replace`, `insert_after`, `delete_lines`)
7. **Save**: `commit_edit(path, summary)`
8. **Verify**: `read_file(path)` or `run_output()`
9. **Report** changes in chat

### NOT Allowed Without Discussion

- Removing existing histograms or canvases
- Changing physics logic (missing mass formulas, etc.)
- Restructuring the macro flow
- Deleting code blocks

## Multi-Page PDF Pattern

```cpp
// Open PDF
TCanvas* c1 = new TCanvas("c1", "Page 1", 1200, 800);
c1->Print((par::pic_file + "(").c_str());  // Open with "("

// Page 1
h_var1->Draw();
c1->Print(par::pic_file.c_str());

// Page 2
c1->Clear();
c1->Divide(2,2);
// ... draw ...
c1->Print(par::pic_file.c_str());

// Close PDF
c1->Print((par::pic_file + ")").c_str());  // Close with ")"
```

## Common Fit Functions

| Function | ROOT Syntax | Parameters |
|----------|-------------|------------|
| Gaussian | `gaus` | amp, mean, sigma |
| Landau | `landau` | amp, mpv, sigma |
| Polynomial | `pol0`, `pol1`, `pol2` | p0, p1, p2, ... |
| Breit-Wigner | `[0]/((x-[1])^2 + [2]^2/4)` | amp, mass, width |
| Langaus | Custom (see commonFunctions.C) | landau⊗gauss |
