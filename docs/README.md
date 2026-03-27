# Documentation Index

Analysis knowledge base for physics analysis — 7 domains, 100 documents.

## System

| Document | Description |
|----------|-------------|
| [claude-code-remote-spec.md](claude-code-remote-spec.md) | Full system architecture (SSH + tmux + MCP) |

---

## `experiment/` — experiment Experiment

### `experiment/detector/` — Detectors

| Document | Description |
|----------|-------------|
| [thresholds.md](experiment/detector/thresholds.md) | Detector thresholds and region IDs |
| [forward.md](experiment/detector/forward.md) | Forward Detector subsystems (DC, EC, FTOF, HTCC, LTCC, RICH) |
| [central.md](experiment/detector/central.md) | Central Detector subsystems (CVT, CTOF, CND) |
| [beamline.md](experiment/detector/beamline.md) | Beamline detectors (FT, Faraday Cup, Moeller) |

### `experiment/data/` — Data Infrastructure

| Document | Description |
|----------|-------------|
| [qadb-charge.md](experiment/data/qadb-charge.md) | Detailed QADB charge extraction |
| [qadb-daq.md](experiment/data/qadb-daq.md) | DAQ efficiency and livetime |
| [hipo-format.md](experiment/data/hipo-format.md) | data file format and structure |
| [banks.md](experiment/data/banks.md) | experiment bank structure (REC::Particle, Scintillator, Cherenkov, etc.) |

### `experiment/pid/` — PID Physics

| Document | Description |
|----------|-------------|
| [electron.md](experiment/pid/electron.md) | Electron PID physics (HTCC, EC sampling fraction) |
| [kaon.md](experiment/pid/kaon.md) | K+ PID physics (dTOF, beta vs p, LTCC veto) |
| [proton.md](experiment/pid/proton.md) | Proton PID physics (beta vs p, mass-squared) |
| [pion.md](experiment/pid/pion.md) | Pion PID physics (Cherenkov thresholds, contamination) |
| [photon.md](experiment/pid/photon.md) | Photon PID physics (EC neutral detection) |

### `experiment/reconstruction/` — Reconstruction

| Document | Description |
|----------|-------------|
| [tracking.md](experiment/reconstruction/tracking.md) | Tracking efficiency vs beam current |
| [timing.md](experiment/reconstruction/timing.md) | Timing calibration (start time, TOF, RF correction) |
| [energy.md](experiment/reconstruction/energy.md) | Energy calibration (EC sampling fraction, momentum correction) |

### `experiment/kinematics/` — Kinematics

| Document | Description |
|----------|-------------|
| [variables.md](experiment/kinematics/variables.md) | Kinematic variables (Q2, W, x_B, t, phi, missing mass) |

---

## `root/` — Coding Patterns

### `root/data/` — Data Reading

| Document | Description |
|----------|-------------|
| [reading.md](root/data/reading.md) | HipoChain setup pattern |
| [particle-api.md](root/data/particle-api.md) | Particle access, properties, detector, MC |
| [architecture.md](root/data/architecture.md) | root architecture |
| [hipo-utils.md](root/data/hipo-utils.md) | data bank access patterns |
| [qadb.md](root/data/qadb.md) | Beam charge and QADB utilities |
| [skim.md](root/data/skim.md) | Skimming data files to ROOT trees |

### `root/pid/` — PID Implementation

| Document | Description |
|----------|-------------|
| [electron.md](root/pid/electron.md) | Electron PID implementation (getByID, EC, HTCC access) |
| [kaon.md](root/pid/kaon.md) | K+ PID implementation (dTOF calculation, LTCC veto code) |
| [proton.md](root/pid/proton.md) | Proton PID implementation (beta, mass-squared, Lambda veto) |
| [pion.md](root/pid/pion.md) | Pion PID implementation (getByID, 4-momentum) |
| [photon.md](root/pid/photon.md) | Photon PID implementation (EC access, missing pi0 method) |

### `root/kinematics/` — Kinematics Code

| Document | Description |
|----------|-------------|
| [lorentz.md](root/kinematics/lorentz.md) | TLorentzVector patterns (construction, invariant mass, missing mass) |
| [frames.md](root/kinematics/frames.md) | Reference frame boosts (CM frame, helicity frame, phi angle) |

### `root/plot/` — Plotting

| Document | Description |
|----------|-------------|
| [histograms.md](root/plot/histograms.md) | Histogram patterns (1D, 2D, struct-based) |
| [binnings.md](root/plot/binnings.md) | Common variable binnings |
| [canvas.md](root/plot/canvas.md) | Canvas, grid, multi-page PDF, draw options, legend |
| [style.md](root/plot/style.md) | ROOT style settings (gStyle, colors, axis labels) |
| [saving.md](root/plot/saving.md) | Saving plots (PDF, PNG, ROOT file output) |

### `root/fit/` — Fitting

| Document | Description |
|----------|-------------|
| [functions.md](root/fit/functions.md) | Fit function examples (Gaussian, BW, custom) |
| [options.md](root/fit/options.md) | Fit options table, draw with fit, procedure |
| [examples.md](root/fit/examples.md) | Fit examples (missing mass, invariant mass, Q2-binned) |
| [template-fit.md](root/fit/template-fit.md) | Template fit technique (TFractionFitter, manual scaling) |

### `root/io/` — File I/O

| Document | Description |
|----------|-------------|
| [inspection.md](root/io/inspection.md) | ROOT file inspection commands |
| [trees.md](root/io/trees.md) | TTree reading/writing (branches, chargeTree pattern) |
| [friends.md](root/io/friends.md) | TTree friends (combining data from multiple files) |

### `root/macros/` — Macro Infrastructure

| Document | Description |
|----------|-------------|
| [template.md](root/macros/template.md) | Standard ROOT macro template |
| [inventory.md](root/macros/inventory.md) | Inventory of all analysis macros |
| [common-modules.md](root/macros/common-modules.md) | commonFunctions.C, commonParams.C, ReadParam.C |
| [execution.md](root/macros/execution.md) | Macro execution patterns and progress indicators |
| [paths.md](root/macros/paths.md) | WORKDIR paths and directory layout |
| [parameters.md](root/macros/parameters.md) | JSON parameter system (ReadParam, param files) |

---

## `analysis/` — This Analysis

### Methods

| Document | Description |
|----------|-------------|
| [pipeline.md](analysis/pipeline.md) | Cut chain quick reference |
| [pipeline-detail.md](analysis/pipeline-detail.md) | Detailed analysis pipeline |
| [cuts.md](analysis/cuts.md) | Cut summary table |
| [kinematics.md](analysis/kinematics.md) | Physics overview and kinematics |
| [branches.md](analysis/branches.md) | ROOT output tree branch names |
| [acceptance.md](analysis/acceptance.md) | Acceptance calculation method |
| [cross-section.md](analysis/cross-section.md) | Cross section formula and parameters |
| [cross-section-detail.md](analysis/cross-section-detail.md) | Cross section formulas and method |
| [cross-section-comparison.md](analysis/cross-section-comparison.md) | Comparison with published data |
| [cs-update.md](analysis/cs-update.md) | Cross section calculation updates |
| [virtual-photon-flux.md](analysis/virtual-photon-flux.md) | Virtual photon flux (Hand vs Gilman) |
| [luminosity.md](analysis/luminosity.md) | Luminosity calculation (charge, target, empty target subtraction) |
| [systematics.md](analysis/systematics.md) | Systematic uncertainties (tracking, PID, acceptance, normalization) |
| [results.md](analysis/results.md) | Analysis results summary (yields, backgrounds, cross sections) |

### `analysis/macros/` — Per-Macro Documentation

| Document | Description |
|----------|-------------|
| [studyVertexCut.md](analysis/macros/studyVertexCut.md) | Z-vertex cut study |
| [studyPIDCut.md](analysis/macros/studyPIDCut.md) | PID cut study (dTOF) |
| [studyMissXCut.md](analysis/macros/studyMissXCut.md) | Missing mass cut study (pi0, Sigma+, Lambda) |
| [templateFit.md](analysis/macros/templateFit.md) | Template fit method |
| [studyEmptyTarget.md](analysis/macros/studyEmptyTarget.md) | Empty target background |
| [calcXsecFromAcpt.md](analysis/macros/calcXsecFromAcpt.md) | calcXsecFromAcpt macro documentation |
| [calcXsecQ2.md](analysis/macros/calcXsecQ2.md) | Q2-binned cross section |
| [eventMixing.md](analysis/macros/eventMixing.md) | Event mixing for background estimation |
| [binningDataset.md](analysis/macros/binningDataset.md) | Dataset binning study |
| [studyKplusPID-overview.md](analysis/macros/studyKplusPID-overview.md) | K+ PID assessment overview |
| [studyKplusPID-m2.md](analysis/macros/studyKplusPID-m2.md) | K+ PID via mass-squared |
| [studyKplusPID-ltcc.md](analysis/macros/studyKplusPID-ltcc.md) | K+ PID via LTCC |
| [studyKplusPID-sideband.md](analysis/macros/studyKplusPID-sideband.md) | K+ PID sideband method |
| [studyKplusPID-mc.md](analysis/macros/studyKplusPID-mc.md) | K+ PID from MC |

---

## `simulation/` — Monte Carlo

### `simulation/generators/` — Event Generators

| Document | Description |
|----------|-------------|
| [overview.md](simulation/generators/overview.md) | Generator macros, physics cases, file inventory, weighting |

### `simulation/gemc/` — GEMC Simulation

| Document | Description |
|----------|-------------|
| [running.md](simulation/gemc/running.md) | GEMC command and options |

### `simulation/reconstruction/` — Reconstruction

| Document | Description |
|----------|-------------|
| [cooking.md](simulation/reconstruction/cooking.md) | recon-util command |

### `simulation/lund/` — LUND Format

| Document | Description |
|----------|-------------|
| [format.md](simulation/lund/format.md) | LUND format specification (header, particle lines, active/inactive) |

### `simulation/external/` — External Generators

| Document | Description |
|----------|-------------|
| [clasdis.md](simulation/external/clasdis.md) | clasdis DIS event generator |
| [aao-norad.md](simulation/external/aao-norad.md) | aao_norad exclusive channel generator |
| [phase-space.md](simulation/external/phase-space.md) | Phase space generator (model-independent acceptance) |

---

## `computing/` — remote server Environment

| Document | Description |
|----------|-------------|
| [batch system.md](computing/batch system.md) | batch system batch system commands and job status |
| [storage.md](computing/storage.md) | remote server storage paths |
| [remote-server.md](computing/remote-server.md) | Remote server environment (modules, shells, tmux, filesystem) |
| [rcdb.md](computing/rcdb.md) | Run Conditions Database (beam energy, current, target, run selection) |
| [coatjava.md](computing/coatjava.md) | COATJAVA reconstruction framework (Event Builder, PID, CCDB) |

---

## `workflow/` — Project Operations

| Document | Description |
|----------|-------------|
| [notion.md](workflow/notion.md) | Notion logging setup |
| [qa.md](workflow/qa.md) | QA plot upload workflow |
| [discord.md](workflow/discord.md) | Discord webhook automation |
| [remote-editing.md](workflow/remote-editing.md) | Remote file editing patterns |
| [git.md](workflow/git.md) | Git workflow (repository structure, commit conventions) |
| [presentation.md](workflow/presentation.md) | Presentation workflow (Discord, Notion, PDF, reports) |

---

## `lessons/` — Self-Improvement Log

| Document | Description |
|----------|-------------|
| [README.md](lessons/README.md) | Purpose, format, count system |
| [coding.md](lessons/coding.md) | Coding mistakes and corrections |
| [physics.md](lessons/physics.md) | Physics mistakes and corrections |
| [workflow.md](lessons/workflow.md) | Workflow mistakes and corrections |
| [style.md](lessons/style.md) | Style mistakes and corrections |
