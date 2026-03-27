---
name: monte-carlo
description: GEMC Monte Carlo simulation, generators, acceptance calculation, and MC-data comparison
---

# Monte Carlo Simulation

## Workflow

1. Generate events with `genUni*.C` (LUND format)
2. Run GEMC simulation
3. Reconstruct with `recon-util`
4. (Optional) Apply Q2-W weights with `genMod.C`
5. Run analysis macros on cooked data

## Key Reminders

- Case 10/11 are **swapped** in `genUniKstar.C` (confirmed 2026-02-15)
- Main acceptance MC: case 16 (OSG 10032, 10051)
- Standard: 10,000 events per file
- Beam energy: 6.535 GeV (primary), 7.546 GeV (higher)

## Knowledge References

- [docs/simulation/generators/overview.md](../../docs/simulation/generators/overview.md) — Generator macros, physics cases, file inventory, weighting, physics constants
- [docs/simulation/gemc/running.md](../../docs/simulation/gemc/running.md) — GEMC simulation commands
- [docs/simulation/reconstruction/cooking.md](../../docs/simulation/reconstruction/cooking.md) — Reconstruction commands
- [docs/analysis/acceptance.md](../../docs/analysis/acceptance.md) — Acceptance calculation method and output
- [docs/analysis/macros/templateFit.md](../../docs/analysis/macros/templateFit.md) — MC-data template fit method
- [docs/computing/batch system.md](../../docs/computing/batch system.md) — Batch job submission for MC generation
- [docs/computing/storage.md](../../docs/computing/storage.md) — Output paths and storage
