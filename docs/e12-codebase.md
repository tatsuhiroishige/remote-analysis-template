# E12-15-008 Codebase Reference

**Server**: farm43
**WORKDIR**: `/home/tatsu/E12`
**Experiment**: JLab E12-15-008 (Hall C, (e,e'K+) hypernuclear spectroscopy)

## Top-level Structure

```
/home/tatsu/E12/
├── HallA-Online-Tritium/   # JLab analyzer (empty, README only)
├── analysis/                # Experimental data analysis (empty, README only)
├── simulation/
│   ├── G4_HES/       (34,320 files)  — HES spectrometer G4 sim
│   ├── G4_HKS/       (18,975 files)  — HKS spectrometer G4 sim
│   ├── G4_bseed/      (1,831 files)  — Bremsstrahlung seed generator
│   ├── G4_eKseed/     (1,023 files)  — (e,e'K+) event generator
│   ├── MissingMass/     (525 files)  — Missing mass spectrum calculator
│   ├── G4_HRS/                       — Placeholder
│   └── SIMC/                         — Placeholder
└── README.md
```

File counts include data/output/input files. Source code is ~534 files total.

---

## G4_HKS — Hadron Kaon Spectrometer

Full Geant4 simulation of the HKS arm. Detects hadrons (K+, pi+, protons).

### Key Files

| File | Lines | Role |
|------|-------|------|
| `HKS.cc` | ~80 | Entry point. `./HKS [macro] [paramfile]` |
| `src/HKSAnalysis.cc` | 1004 | ROOT TTree output (all detector hits) |
| `src/HKSDetectorConstruction.cc` | 691 | Full spectrometer geometry |
| `src/HKSPhysicsList.cc` | 485 | EM + hadron + ion + muon physics |
| `src/HKSPrimaryGeneratorAction.cc` | 176 | Particle gun (p/K+/pi+/e+/gamma/e-) |
| `src/HKSParamMan.cc` | 130 | Parameter file reader |

### Spectrometer Elements

| Category | Elements |
|----------|----------|
| **Magnets** | Q1Magnet, Q2Magnet, DMagnet (dipole), PCS (post-collimator splitter) |
| **Field maps** | Q1FieldMan, Q2FieldMan, DFieldMan, PCSFieldMan, HKSField |
| **Tracking** | DriftChamber, ChamberExtension, ChamberExtension2 |
| **TOF** | HTOF1X, HTOF1Y, HTOF2X |
| **PID** | AerogelC (Aerogel Cherenkov), WaterC (Water Cherenkov), CEF |
| **Target** | Target, TargetChamber |
| **Virtual** | VirtualDetector, VDetectorPB (16 VDs defined in Define.hh) |
| **Other** | SieveSlit, Collimator, BeamLineElement, NMRPort, DetectorHut |

### Analysis Macros (ana/)

| Directory | Key macros | Purpose |
|-----------|-----------|---------|
| `ishigemacro/ana_macro/` | `acpt.cc`, `optimization.cc`, `cutBehavior.cc`, `vpflux_mc.cc`, `plotMacro.cc` | Acceptance, optimization, virtual photon flux |
| `ishigemacro/scan/` | `scan_analyzer.cc`, `Qscan_analyzer.cc`, `inputFileLooper.cc` | Q-value scanning, batch parameter sweep |
| `akiyamacro/` | `anaSieveSlit.C`, `anaScanPCS.C`, `anaScanQ1Q2.C`, `anaZReso.C` | Sieve slit, PCS scan, Q1Q2 scan, Z resolution |
| `okuyamacro/` | `calcMatrix.C`, `resolution.cc`, `solid.C`, `vpflux_mc.cc` | Transfer matrix, resolution, solid angle |
| `macros/` | `calcMatrix.C`, `getMatrix.cc/h`, `resolution.cc`, `solid.C` | Base transfer matrix tools |

### Build

CMake + Geant4 + ROOT. `CMakeLists.txt` uses `root-config` for includes/libs.

---

## G4_HES — High-resolution Electron Spectrometer

Full Geant4 simulation of the HES arm. Detects scattered electrons.

### Differences from HKS

| Feature | HKS | HES |
|---------|-----|-----|
| Drift chambers | DriftChamber + ChamberExtension | **EDC1, EDC2** |
| Hodoscopes | HTOF1X/Y, HTOF2X | **EHodo1, EHodo2** |
| Splitter | (none) | **SplitterMagnet + SplitterFieldMan** |
| PID detectors | AerogelC, WaterC, CEF | (none, electron arm) |
| Sieve slit | SieveSlit | SieveSlit |
| Additional VDs | VDetectorPB | VDetectorPB + **VDetectorQ1, VDetectorQ2** |

### Analysis Macros (ana/ishigemacro/)

| Macro | Purpose |
|-------|---------|
| `acceptance.cc` | HES acceptance calculation |
| `bg_calc.cc` | Background rate calculation |
| `centralRay.cc` | Central ray optics |
| `mm_acpt.cc` | Missing mass acceptance |
| `qscan.cc` | Q-value scan |
| `resolution.cc` | Momentum resolution |
| `matrix.cc` | Transfer matrix |
| `check.cc` | General checks |

Supporting libraries in `src/`: BTMatrix, Pepk, ReadBranch, ReadFile, Reso, Setting, Solid, VDDist, VDPos, moller

---

## G4_bseed — Bremsstrahlung Seed Generator

Simplified Geant4 sim that generates bremsstrahlung photon seeds at the target. Modern G4 style (ActionInitialization pattern).

### Key Files

| File | Role |
|------|------|
| `main.cc` | Entry point with `ActionInitialization` pattern |
| `src/PrimaryGeneratorAction.cc` | Beam electron → bremsstrahlung |
| `src/Analysis.cc` | ROOT output |
| `src/DetectorConstruction.cc` | Simplified geometry (target + VDs) |
| `param/*/replicate_loop.cc` | Batch job parameter replication |

### Target configurations

- `param/Ca40_2023Aug12/` — Ca-40 target
- `param/Ca48_2024Jun09/` — Ca-48 target
- `param/mm_test/` — Missing mass test

---

## G4_eKseed — (e,e'K+) Event Generator

Geant4-based generator for electroproduction events. Includes **cross section models** for various channels.

### Cross Section Models (src/CS/)

| Model | Channels |
|-------|----------|
| **CLAS** | K+Lambda, K+Sigma0, K-n Sigma- |
| **KMaid** | K+Lambda, K+Sigma0, K-n Sigma- |
| **RPR2007** | K+Lambda, K+Sigma0, K-n Sigma- |
| **RPR2011** | K+Lambda |
| **SaclayLyon** | K+Lambda, K+Sigma0, K-n Sigma-, A variant for K+Lambda |

### Key Files

| File | Role |
|------|------|
| `main.cc` | Entry point |
| `src/PrimaryGeneratorAction.cc` | Event generation with CS weighting |
| `include/CS/CSTable.hh` | Cross section table interface |
| `ana/fermi.cc` | Fermi momentum analysis |

### Target configurations

- `param/Ca40_2024May15/` — Ca-40
- `param/Ca48_2024Jun09/` — Ca-48

---

## MissingMass — Missing Mass Spectrum Calculator

Standalone ROOT macros (not Geant4) for missing mass spectrum computation.

### Create_Param/

| Macro | Purpose |
|-------|---------|
| `create.cc` | Create parameter sets |
| `setupParam.cc/h` | Parameter setup |
| `completeParam.cc/h` | Complete parameter configuration |
| `extract_gs.cc` | Extract ground state parameters |
| `Setting.cc/h` | Configuration management |

### MissingMass_Calc/

| Macro | Purpose |
|-------|---------|
| `mm_eeK.cc/h` | Main (e,e'K+) missing mass calculator |
| `mm_gs.cc` | Ground state spectrum |
| `mm_Mg27L.cc` | Mg-27 Lambda spectrum |
| `mm_angle.cc` | Angular dependence |
| `mm_fullsim.cc` | Full simulation spectrum |
| `mm_montecarlo.cc` | Monte Carlo spectrum |
| `thick_depend.cc` | Target thickness dependence (data) |
| `thick_dependMC.cc` | Target thickness dependence (MC) |
| `thick_dependMCfit.cc` | Thickness dependence fitting |
| `current_dependMC.cc` | Beam current dependence (MC) |
| `check_MCfit.cc` | MC fit validation |
| `legacy/` | Older versions (v1, select_event, calc_spectrum) |

---

## Estimated Analysis Flow

```
[1] G4_bseed          Bremsstrahlung photon generation at target
        │
        ▼
[2] G4_eKseed         (e,e'K+) event generation with CS models
        │                (CLAS, KMaid, RPR, SaclayLyon)
        │
        ├──────────────────────────┐
        ▼                          ▼
[3] G4_HES                   [4] G4_HKS
    Scattered e' transport        K+ transport through
    through HES magnets           HKS magnets (Q1,Q2,D)
    (Q1,Q2,D,Splitter)           + detector response
    + detector response           (DC, TOF, AC, WC)
    (EDC1/2, EHodo1/2)
        │                          │
        └────────────┬─────────────┘
                     ▼
[5] Analysis macros (ana/ishigemacro/)
    - Transfer matrix (calcMatrix, getMatrix)
    - Acceptance (acpt.cc, acceptance.cc)
    - Resolution (resolution.cc)
    - Solid angle (solid.C)
    - Q-value scan (qscan.cc, scan_analyzer)
    - Virtual photon flux (vpflux_mc.cc)
                     │
                     ▼
[6] MissingMass/
    - mm_eeK: Full missing mass spectrum
    - mm_gs: Ground state extraction
    - thick_depend*: Systematic studies
    - Cross section extraction
```

### Per-target workflow

1. **Seed generation**: G4_bseed with target params (Ca40 or Ca48)
2. **Event generation**: G4_eKseed with CS model selection
3. **Spectrometer simulation**: G4_HES (e') + G4_HKS (K+) transport
4. **Acceptance**: ana/ishigemacro — acceptance, resolution, matrix
5. **Physics**: MissingMass — spectrum, systematics, cross sections
