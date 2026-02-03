# ROOT Analysis Rules

## Philosophy

1. **Physics-first** - Code structure reflects physics workflow
2. **Modularity** - Small, single-purpose macros (`study*.C`, `select*.C`)
3. **Explicitness** - No magic numbers, all cuts visible
4. **Reproducibility** - Every macro runnable independently

## Coding Style

- Explicit histogram binning (never rely on defaults)
- Meaningful names: `h_pt`, `h_mass`, `h_eta`
- CSV-like output: `step, n_total, n_after, efficiency`
- Store fit results in structs (not local scope only)

## Execution

- Run from `macro/` directory
- Use `root -b -q` for batch mode
- **Never compile** unless needed (no `+`, no ACLiC)
- Batch mode for remote: `gROOT->SetBatch(true)`

## Analysis Flow

```
INPUT → HISTOGRAMS → EVENT LOOP → POST-LOOP → CANVAS → OUTPUT
```

## Naming

| Type | Pattern |
|------|---------|
| Study | `study<Topic>.C` |
| Selection | `select<What>.C` |
| Calculation | `calc<What>.C` |
| Comparison | `compare<What>.C` |
