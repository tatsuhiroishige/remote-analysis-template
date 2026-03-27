# Documentation Rule

## Auto-Update Docs

When you learn something new during analysis that is **stable and verified**, update the relevant doc file.

### What to Document

| Trigger | Action |
|---------|--------|
| New macro created | Add entry to `docs/root/macros/inventory.md` |
| New cut value determined | Update `docs/analysis/cuts.md` |
| New API pattern discovered | Update relevant `docs/root/` file |
| New physics finding | Update relevant `docs/analysis/` or `docs/experiment/` file |
| New computing trick | Update relevant `docs/computing/` file |

### What NOT to Document

- Temporary debugging attempts
- Unverified hypotheses
- Session-specific context (use MEMORY.md for that)

### Placeholder Files

Many docs are placeholders (contain only `<!-- TODO: ... -->`). When you have verified knowledge to fill in:
1. Replace the TODO comment with real content
2. Follow the existing doc style (tables, code blocks, headings)
3. Update `docs/README.md` description if the doc scope changed

### Doc Structure

Follow the 7-domain hierarchy:
- `experiment/` — Experiment knowledge (detectors, PID physics, kinematics)
- `root/` — Coding patterns (API, data reading, plotting, fitting)
- `analysis/` — This analysis (methods + per-macro docs in `macros/`)
- `simulation/` — MC chain (generators, GEMC, reconstruction)
- `computing/` — Remote infra (server, batch jobs, storage)
- `workflow/` — Project ops (notion, QA, discord)
- `lessons/` — Self-improvement log
