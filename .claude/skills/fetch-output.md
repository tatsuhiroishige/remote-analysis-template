# fetch-output

Copy output files from the remote server to local machine.

## Usage
```
/fetch-output <filename> [type]
```

## Examples
```
/fetch-output analysis_results.pdf
/fetch-output output.root
/fetch-output studyAcceptance_exp.pdf pic
```

## Instructions

### 1. Determine file location

| Type | Remote Path | Local Path |
|------|-------------|------------|
| PDF (default) | `$WORKDIR/pic/` | `output/` |
| ROOT | `$WORKDIR/root/` | `output/` |
| Custom | Specify full path | `output/` |

### 2. Copy file

```bash
# PDF files
scp $HOST:\$WORKDIR/pic/<filename> output/

# ROOT files
scp $HOST:\$WORKDIR/root/<filename> output/

# Custom path
scp $HOST:<full_path> output/
```

### 3. Verify download

```bash
ls -la output/<filename>
```

### 4. Report to user

- File size
- Local path where saved
- Suggest next actions (view, analyze, share)

## Notes

- Creates `output/` directory if it doesn't exist
- For PDF viewing on macOS: `open output/<filename>`
- For ROOT file inspection: `/check-root output/<filename>`
