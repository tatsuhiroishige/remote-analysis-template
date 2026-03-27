---
name: data-reading
description: Data format, ROOT API, particle access patterns, and data reading
---

# data Data & root API

## Workflow

1. Set up HipoChain with QADB pass
2. Get C12Reader
3. Event loop with `chain.Next()`
4. Access particles via `c12->getByID(pid)`
5. Apply cuts and fill histograms

## Key Reminders

- Always set `chain.db()->setPass("pass1")` BEFORE event loop
- `info_Kp` has **capital K** (from `GetBranchBaseName("K+")`)
- Use `root` (not `root`) for data files

## Knowledge References

- [docs/root/data/reading.md](../../docs/root/data/reading.md) — HipoChain setup pattern
- [docs/root/data/particle-api.md](../../docs/root/data/particle-api.md) — Particle access, properties, detector, MC
- [docs/analysis/branches.md](../../docs/analysis/branches.md) — ROOT output tree branch names
- [docs/root/data/qadb.md](../../docs/root/data/qadb.md) — Beam charge and QADB utilities
- [docs/experiment/data/qadb-charge.md](../../docs/experiment/data/qadb-charge.md) — Detailed QADB charge extraction
- [docs/experiment/data/qadb-daq.md](../../docs/experiment/data/qadb-daq.md) — DAQ efficiency and livetime
- [docs/root/data/architecture.md](../../docs/root/data/architecture.md) — root architecture
- [docs/root/data/hipo-utils.md](../../docs/root/data/hipo-utils.md) — data bank access patterns
- [docs/experiment/detector/thresholds.md](../../docs/experiment/detector/thresholds.md) — Detector thresholds and region IDs
