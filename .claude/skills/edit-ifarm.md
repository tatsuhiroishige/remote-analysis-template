# edit-ifarm

Edit files on the remote server using Python patch scripts.

## Usage
```
/edit-ifarm <filepath> <old_text> <new_text>
```

## Examples
```
/edit-ifarm macro/analysis.C "pt_min = 0.5" "pt_min = 1.0"
/edit-ifarm param/params.json '"file_count": 10' '"file_count": 50'
```

## Instructions

### 1. Always backup first

```bash
ssh $HOST "cp \$WORKDIR/<filepath> \$WORKDIR/<filepath>.bak"
```

### 2. Create Python patch script locally

```python
#!/usr/bin/env python3
import sys

filepath = sys.argv[1]
with open(filepath, "r") as f:
    content = f.read()

old_text = '''<old_text>'''
new_text = '''<new_text>'''

if old_text in content:
    with open(filepath, "w") as f:
        f.write(content.replace(old_text, new_text, 1))
    print("SUCCESS: Replaced text")
else:
    print("ERROR: Text not found")
    sys.exit(1)
```

Save to: `scripts/patch_<name>.py`

### 3. Transfer and execute

```bash
scp scripts/patch_<name>.py $HOST:~/tmp/
ssh $HOST "python3 ~/tmp/patch_<name>.py \$WORKDIR/<filepath>"
```

### 4. Verify change

```bash
ssh $HOST "grep -n '<search_pattern>' \$WORKDIR/<filepath>"
```

Or diff with backup:
```bash
ssh $HOST "diff \$WORKDIR/<filepath>.bak \$WORKDIR/<filepath>"
```

## Undo Changes

```bash
ssh $HOST "cp \$WORKDIR/<filepath>.bak \$WORKDIR/<filepath>"
```

## Common Edit Patterns

| Task | Old | New |
|------|-----|-----|
| Change cut value | `pt_min = 0.5` | `pt_min = 1.0` |
| Toggle flag | `"batch_flag": false` | `"batch_flag": true` |
| Update path | `"/old/path/"` | `"/new/path/"` |

## Why Python (not sed)?

- Shell quoting can be tricky (especially tcsh)
- Python handles multi-line and special characters reliably
- Explicit error handling (reports if text not found)

## Notes
- Always backup before editing
- Use `replace(..., 1)` to replace only first occurrence
