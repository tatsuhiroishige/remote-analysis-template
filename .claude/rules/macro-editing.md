---
trigger: always_on
---

# Macro Editing Policy

## Typical Analysis Structure

ROOT macros follow this standard flow:

```
1. INPUT        → Read data (ROOT/other files)
2. HISTOGRAMS   → Define TH1D, TH2D with explicit binning
3. EVENT LOOP   → Loop with cut conditions, fill histograms
4. POST-LOOP    → Fitting, calculations, normalization
5. CANVAS       → Create canvas, draw histograms
6. OUTPUT       → Save to PDF and ROOT file
```

## Allowed Edits

Claude Code MAY edit macros to:

### 1. Add Histograms
```cpp
// Add new histogram definition
TH1D* h_newVar = new TH1D("h_newVar", "Title;X [unit];Counts", nbins, xmin, xmax);

// Add fill in event loop
h_newVar->Fill(variable);
```

### 2. Add Canvas and Draw
```cpp
// Add new canvas page
TCanvas* c2 = new TCanvas("c2", "New Plots", 1200, 800);
c2->Divide(2, 2);  // 2x2 grid

c2->cd(1);
h_var1->Draw();

c2->cd(2);
h_var2->Draw();

c2->cd(3);
h_var3->SetLineColor(kRed);
h_var3->Draw();

c2->cd(4);
h2_2d->Draw("COLZ");

// Add to existing PDF (use same filename)
c2->Print(output_file.c_str());  // Appends page to PDF
```

### 3. Add Fitting
```cpp
// After event loop, before canvas

// Gaussian fit
TF1* f_gaus = new TF1("f_gaus", "gaus", fit_min, fit_max);
h_mass->Fit(f_gaus, "R");  // R = use range

// Gaussian + polynomial background
TF1* f_signal = new TF1("f_signal", "gaus(0)+pol2(3)", fit_min, fit_max);
f_signal->SetParameters(amplitude, mean, sigma, p0, p1, p2);
h_mass->Fit(f_signal, "R");

// Print fit results
std::cout << "Fit Results:" << std::endl;
std::cout << "Mean: " << f_gaus->GetParameter(1) << " +/- " << f_gaus->GetParError(1) << std::endl;
std::cout << "Sigma: " << f_gaus->GetParameter(2) << " +/- " << f_gaus->GetParError(2) << std::endl;
std::cout << "Chi2/NDF: " << f_gaus->GetChisquare() / f_gaus->GetNDF() << std::endl;

// Draw with fit
c1->cd(1);
h_mass->Draw();
f_gaus->Draw("same");
```

### 4. Modify Cut Values
```cpp
// Change existing cut
if(pt > 0.5)  →  if(pt > 1.0)

// Add new cut
if(eta < 2.5) continue;
```

### 5. Change Parameters
```cpp
// Binning
TH1D("h", "title", 100, 0, 10)  →  TH1D("h", "title", 200, 0, 20)

// Flags
pdf_flag = false  →  pdf_flag = true
```

## Multi-Page PDF Pattern

```cpp
// Open PDF
TCanvas* c1 = new TCanvas("c1", "Page 1", 1200, 800);
c1->Print((output_file + "(").c_str());  // Open with "("

// Page 1
h_var1->Draw();
c1->Print(output_file.c_str());

// Page 2
c1->Clear();
c1->Divide(2,2);
// ... draw ...
c1->Print(output_file.c_str());

// Page 3
c1->Clear();
h_var2->Draw();
c1->Print(output_file.c_str());

// Close PDF
c1->Print((output_file + ")").c_str());  // Close with ")"
```

## Common Fit Functions

| Function | ROOT Syntax | Parameters |
|----------|-------------|------------|
| Gaussian | `gaus` | amp, mean, sigma |
| Landau | `landau` | amp, mpv, sigma |
| Polynomial | `pol0`, `pol1`, `pol2` | p0, p1, p2, ... |
| Breit-Wigner | `[0]/((x-[1])^2 + [2]^2/4)` | amp, mass, width |

## Edit Procedure

1. **Explain** what will be added/changed
2. **Show** the code to be inserted
3. **Identify** where in the macro (section: HISTOGRAMS, LOOP, POST-LOOP, CANVAS)
4. **Ask** for approval
5. **Backup** original file
6. **Execute** edit
7. **Verify** change was applied

## NOT Allowed Without Discussion

- Removing existing histograms or canvases
- Changing physics logic (formulas, etc.)
- Restructuring the macro flow
- Deleting code blocks
