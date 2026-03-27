---
trigger: always_on
---

# Coding Conventions

## Philosophy

1. **Physics-first** — Code structure reflects physics workflow
2. **Modularity** — Small, single-purpose macros (`study*.C`, `select*.C`)
3. **Explicitness** — No magic numbers, all cuts visible
4. **Reproducibility** — Every macro runnable independently
5. **One macro per step** — Each pipeline step has exactly one unified macro (no per-channel duplicates)

## Coding Style

- ROOT 6 / C++17
- Explicit histogram binning (never rely on defaults)
- Meaningful names: `h_Q2`, `h_mass`, `h_pt`
- CSV-like output: `step, n_total, n_after, efficiency`
- Store fit results in structs (not local scope only)

## Execution

- Run from `macro/` directory via MCP: `run("cd macro && root ...")`
- Use `root` (not `root`) for data files
- Pure ROOT macros (data-format independent) can use `root -l -b -q`
- **Never compile** (no `+`, no ACLiC)
- Batch mode for remote: `gROOT->SetBatch(true)`

## Analysis Flow

```
INPUT → HISTOGRAMS → EVENT LOOP → POST-LOOP → CANVAS → OUTPUT
```

## Pipeline Architecture

### Main Pipeline (<PARTICLE> / <PARTICLE_2>)

| Step | Macro | Description |
|------|-------|-------------|
| 1 | `studyVertexCut.C` | Event selection (all channels) |
| 2 | `templateFit.C` | Template fit (L1405, L1520, <CHANNEL>) |
| 3 | `calcAcptRatio.C` | Lambda acceptance (L1405, L1520) |
| 4 | `applyAcptCorrection.C` | Acceptance correction (L1405, L1520) |
| 5 | `calcXsec.C` | Cross section (L1405, L1520, <CHANNEL>) |

### Sub-Pipeline (<CHANNEL> validation)

| Step | Macro | Description |
|------|-------|-------------|
| S1 | `calc<CHANNEL>Acpt.C` | <CHANNEL> acceptance (ROOT tree + N_gen estimate) |
| S2 | `calcXsec.C` (<CHANNEL> mode) | <CHANNEL> cross section |

Study macros (`studyPIDCut.C`, `studyMissXCut.C`) and plot macros (`plot<CHANNEL>XsecComparison.C`) are **not** pipeline steps — they are standalone investigation/visualization tools.

## Macro Naming

| Type | Pattern | Example |
|------|---------|---------|
| Study | `study<Topic>.C` | `studyVertexCut.C` |
| Selection | `select<What>.C` | `selectLambda.C` |
| Calculation | `calc<What>.C` | `calcXsec.C` |
| Application | `apply<What>.C` | `applyAcptCorrection.C` |
| Comparison | `compare<What>.C` | `compareXsec.C` |
| Plot | `plot<What>.C` | `plot<CHANNEL>XsecComparison.C` |
| Check | `check<What>.C` | `checkCharge.C` |

## Directory Layout (on remote server)

```
$WORKDIR/
├── macro/          ← ROOT macros (run from here)
├── param/          ← JSON parameter files
├── root/           ← Output ROOT files
├── pic/            ← Output PDF files
├── log/            ← Log files
├── common/         ← Shared modules (commonFunctions.C, commonParams.C, ReadParam.C)
└── docs/           ← Documentation
```

## Parameter Files

- JSON format: `param/params_<macroName>.json`
- Read via `ReadParam` class
- Contains: flags, data sources, binning, output paths
- Label construction: `use_exp` → "exp", `use_sim` → "sim", `use_both` → "both"

## Common Modules

| Module | Purpose |
|--------|---------|
| `commonFunctions.C` | Shared utility functions |
| `commonParams.C` | Run lists, physics constants |
| `ReadParam.C` | JSON parameter reader |
