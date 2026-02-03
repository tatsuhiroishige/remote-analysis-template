# add-fitting

Add fitting to a histogram.

## Usage
```
/add-fitting <macro> <histogram> <function> [range]
```

## Examples
```
/add-fitting analysis h_mass gaus "1.0, 1.4"
/add-fitting study h_peak "gaus+pol2" "0.5, 1.5"
```

## Code Templates

### Gaussian Fit

```cpp
// After event loop, before canvas
TF1* f_gaus = new TF1("f_gaus", "gaus", xmin, xmax);
h_mass->Fit(f_gaus, "R");  // R = range only

// Get parameters
double mean  = f_gaus->GetParameter(1);
double sigma = f_gaus->GetParameter(2);

// Print results
std::cout << "Mean: " << mean << " +/- " << f_gaus->GetParError(1) << std::endl;
std::cout << "Sigma: " << sigma << " +/- " << f_gaus->GetParError(2) << std::endl;
std::cout << "Chi2/NDF: " << f_gaus->GetChisquare() / f_gaus->GetNDF() << std::endl;
```

### Gaussian + Polynomial Background

```cpp
TF1* f_sig = new TF1("f_sig", "gaus(0)+pol2(3)", xmin, xmax);
// Parameters: [0]=amp, [1]=mean, [2]=sigma, [3]=p0, [4]=p1, [5]=p2

// Set initial parameters
f_sig->SetParameter(0, h_mass->GetMaximum());
f_sig->SetParameter(1, 1.0);   // Expected peak position
f_sig->SetParameter(2, 0.05);  // Expected width

h_mass->Fit(f_sig, "R");
```

### Landau Fit

```cpp
TF1* f_landau = new TF1("f_landau", "landau", xmin, xmax);
h_energy->Fit(f_landau, "R");

double mpv = f_landau->GetParameter(1);  // Most probable value
```

### Double Gaussian

```cpp
TF1* f_double = new TF1("f_double", "gaus(0)+gaus(3)", xmin, xmax);
f_double->SetParameter(1, 1.0);  // First peak
f_double->SetParameter(4, 1.5);  // Second peak

h_mass->Fit(f_double, "R");
```

## Fit Options

| Option | Meaning |
|--------|---------|
| `R` | Use function range only |
| `Q` | Quiet mode |
| `L` | Log-likelihood fit |
| `E` | Better error estimation |
| `S` | Return TFitResult |

Example: `h->Fit(f, "RQE")`

## Draw with Fit

```cpp
// In CANVAS section
c1->cd(1);
h_mass->Draw();
f_gaus->SetLineColor(kRed);
f_gaus->Draw("same");

gStyle->SetOptFit(1111);  // Show fit parameters
```

## Common Functions

| Name | ROOT | Parameters |
|------|------|------------|
| Gaussian | `gaus` | amp, mean, sigma |
| Landau | `landau` | amp, mpv, sigma |
| Polynomial | `pol0-9` | p0, p1, ... |
| Exponential | `expo` | const, slope |

## Procedure

1. Identify histogram to fit
2. Choose function and range
3. Add fit code in POST-LOOP section
4. Add drawing in CANVAS section
5. Create edit with `/edit-ifarm`
