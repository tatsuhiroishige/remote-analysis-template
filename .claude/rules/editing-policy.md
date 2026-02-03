# Macro Editing Policy

## Allowed Edits

Claude MAY edit macros to:

| Edit | Section | Skill |
|------|---------|-------|
| Add histogram | HISTOGRAMS + LOOP | `/add-histogram` |
| Add canvas/PDF page | CANVAS | `/add-canvas` |
| Add fitting | POST-LOOP | `/add-fitting` |
| Change cut values | LOOP | `/edit-ifarm` |
| Change parameters | Any | `/edit-ifarm` |

## Edit Procedure

1. Explain what will change
2. Show the code
3. **Ask approval**
4. Backup (`.bak`)
5. Execute
6. Verify

## NOT Allowed (ask first)

- Remove existing histograms/canvases
- Change physics formulas
- Restructure macro flow
- Delete code blocks
