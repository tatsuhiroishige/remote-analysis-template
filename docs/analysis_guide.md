# Analysis Guide

This guide explains how to use Claude Code for remote ROOT-based physics analysis.

---

## Getting Started

### 1. Configure Your Environment

Edit `.claude/CLAUDE.md` with your settings:

```markdown
| Item | Value |
|------|-------|
| **WORKDIR** | `~/your/analysis/directory/` |
| **Shell** | bash (or tcsh, zsh) |
| **SSH alias** | `myserver` |
| **tmux session** | `claude` |
```

### 2. Set Up Remote Directory Structure

```bash
ssh myserver "mkdir -p ~/analysis/{macro,param,root,pic,log}"
```

### 3. Verify Connection

```
/ifarm-status
```

---

## Typical Analysis Workflow

### Overview

```
Raw Data → Cut Studies → Background Estimation → Signal Extraction → Systematics
              ↓                    ↓                    ↓
        (vertex, PID, MM)   (mixing, sideband)    (fitting, yield)
```

### Standard Macro Types

| Type | Naming | Purpose |
|------|--------|---------|
| Study | `study<Topic>.C` | Investigate cuts, optimize selection |
| Selection | `select<What>.C` | Apply cuts, create skims |
| Calculation | `calc<What>.C` | Compute physics quantities |
| Comparison | `compare<What>.C` | Compare data/MC, systematic variations |

---

## Cut Flow Pattern

A typical particle physics analysis applies cuts sequentially:

### 1. Vertex Selection
Ensure particles originate from the target:

```cpp
// Example: Z-vertex cut
if(vz < vz_min || vz > vz_max) continue;
```

### 2. Particle Identification (PID)
Select desired particle species:

```cpp
// Example: TOF-based PID
double beta_expected = p / sqrt(p*p + mass*mass);
double dBeta = beta_measured - beta_expected;
if(fabs(dBeta) > cut_dBeta) continue;
```

### 3. Kinematic Selection
Apply physics-motivated cuts:

```cpp
// Example: Missing mass cut
TLorentzVector missing = beam + target - p1 - p2 - p3;
double MM2 = missing.M2();
if(MM2 < MM2_min || MM2 > MM2_max) continue;
```

### 4. Background Rejection
Remove known backgrounds:

```cpp
// Example: Reject specific resonance
double M_inv = (p1 + p2).M();
if(fabs(M_inv - resonance_mass) < exclusion_window) continue;
```

---

## Background Estimation Techniques

### Event Mixing

Models combinatorial (accidental) background:

```cpp
// Concept:
// 1. Keep one particle fixed (e.g., trigger particle)
// 2. Randomly select other particles from event pool
// 3. Calculate observables
// 4. Repeat N times for statistics

for(int imix = 0; imix < n_mix; imix++) {
    // Select random particles from pool
    int idx1 = random.Integer(pool1.size());
    int idx2 = random.Integer(pool2.size());

    // Calculate mixed observable
    TLorentzVector mixed = pool1[idx1] + pool2[idx2];
    h_mixed->Fill(mixed.M());
}
```

**Normalization**: Scale to data in signal-free region.

### Sideband Subtraction

For intermediate resonance selection:

```
Signal Region: |M - M_peak| < 3σ
Sideband: 5σ < |M - M_peak| < 8σ

N_signal = N_peak_region - N_sideband × (width_signal / width_sideband)
```

### Empty Target / Background Run

Remove target material backgrounds:

```
N_physics = N_full - N_background × (Charge_full / Charge_background)
```

---

## Signal Extraction

### Common Fit Functions

| Function | ROOT Syntax | Use Case |
|----------|-------------|----------|
| Gaussian | `gaus` | Detector resolution peaks |
| Landau | `landau` | Energy loss distributions |
| Breit-Wigner | `[0]/((x-[1])^2+[2]^2/4)` | Resonance line shapes |
| Polynomial | `pol0`, `pol1`, `pol2` | Background modeling |
| Gaussian + Pol | `gaus(0)+pol2(3)` | Signal + background |

### Fit Example

```cpp
// Define fit function: Gaussian signal + polynomial background
TF1* f_fit = new TF1("f_fit", "gaus(0)+pol2(3)", fit_min, fit_max);

// Set initial parameters
f_fit->SetParameters(amplitude, mean, sigma, p0, p1, p2);

// Perform fit
h_mass->Fit(f_fit, "R");  // R = use specified range

// Extract results
double yield = f_fit->GetParameter(0) * sqrt(2*TMath::Pi()) * f_fit->GetParameter(2);
double yield_err = yield * sqrt(pow(f_fit->GetParError(0)/f_fit->GetParameter(0), 2) +
                                 pow(f_fit->GetParError(2)/f_fit->GetParameter(2), 2));

// Print results
cout << "Yield: " << yield << " +/- " << yield_err << endl;
cout << "Mean: " << f_fit->GetParameter(1) << " +/- " << f_fit->GetParError(1) << endl;
cout << "Chi2/NDF: " << f_fit->GetChisquare() / f_fit->GetNDF() << endl;
```

---

## Systematic Uncertainties

### Cut Variation Method

Vary each cut from nominal to tight/loose:

| Cut | Nominal | Tight | Loose |
|-----|---------|-------|-------|
| MM | [a, b] | [a+δ, b-δ] | [a-δ, b+δ] |
| PID | < x | < x-δ | < x+δ |

**Quantification**:
```
δ_sys = |result_nominal - result_varied| / result_nominal
```

### Global Systematic

Combine variations across all bins using RMS of pull distribution:

```
pull_i = (result_varied_i - result_nominal_i) / stat_error_i
systematic = RMS(pull distribution)
```

---

## Using Claude Code for Analysis

### Start an Analysis Task

```
/start-analysis Study vertex cuts for K+ selection
```

Claude will:
1. Create a todo file in `todo/`
2. Present the plan for approval
3. Execute after confirmation

### Run a Macro

```
/run-macro studyVertexCut params_vertex.json
```

### Monitor Progress

```
/check-tmux 50
```

### Inspect ROOT Output

```
/check-root output.root
```

### Fetch Results

```
/fetch-output vertex_study.pdf
```

### Edit Remote Parameters

```
/edit-ifarm param/params.json '"cut_min": 0.5' '"cut_min": 0.6'
```

---

## Best Practices

### 1. Always Use Batch Mode

```cpp
gROOT->SetBatch(true);  // Required for remote execution
```

### 2. Explicit Histogram Binning

```cpp
// Good: explicit binning
TH1D* h = new TH1D("h", "title;X;Counts", 100, 0, 10);

// Bad: default binning
TH1D* h = new TH1D("h", "title", 100);
```

### 3. CSV-like Output for Parsing

```cpp
cout << "step, n_before, n_after, efficiency" << endl;
cout << "vertex, " << n_total << ", " << n_vertex << ", " << (double)n_vertex/n_total << endl;
cout << "PID, " << n_vertex << ", " << n_pid << ", " << (double)n_pid/n_vertex << endl;
```

### 4. Save Histograms to ROOT File

```cpp
TFile* f_out = new TFile("../root/output.root", "RECREATE");
h_mass->Write();
h_pt->Write();
f_out->Close();
```

### 5. Multi-page PDF Output

```cpp
// Open PDF
c1->Print((output_file + "(").c_str());

// Add pages
h1->Draw(); c1->Print(output_file.c_str());
h2->Draw(); c1->Print(output_file.c_str());

// Close PDF
c1->Print((output_file + ")").c_str());
```

---

## Example: Complete Cut Study Workflow

```
User: "Study the effect of vertex cuts on signal purity"

1. Claude creates todo/2026-02-03_vertex_study.md
2. User approves the plan
3. Claude runs:
   - /run-macro studyVertexCut params_vertex.json
   - /check-tmux (monitors progress)
   - /fetch-output vertex_study.pdf
   - /upload-qa vertex_study.pdf "Vertex cut optimization"
4. Claude logs results to Notion
5. Claude reports summary to user
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| ROOT session stuck | `/kill-root interrupt` |
| Cut not working | Check histogram before/after cut |
| Fit fails | Check initial parameters, range |
| Low statistics | Reduce binning, combine bins |
| Background dominates | Tighten cuts, improve mixing model |

---

## References

- [ROOT Documentation](https://root.cern/doc/master/)
- [TH1 Fitting](https://root.cern/doc/master/classTH1.html#a63eb028df86bc86c8e20c989eb23fb2a)
- [TLorentzVector](https://root.cern/doc/master/classTLorentzVector.html)
