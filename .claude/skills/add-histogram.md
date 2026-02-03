# add-histogram

Add a new histogram to a macro.

## Usage
```
/add-histogram <macro> <variable> [options]
```

## Examples
```
/add-histogram analysis pt
/add-histogram study mass "100, 0, 5"
```

## Code Templates

### 1D Histogram

**In HISTOGRAMS section:**
```cpp
TH1D* h_varName = new TH1D("h_varName", "Title;X-axis [unit];Counts", nbins, xmin, xmax);
```

**In EVENT LOOP:**
```cpp
h_varName->Fill(variable);
```

### 2D Histogram

**In HISTOGRAMS section:**
```cpp
TH2D* h2_var1_var2 = new TH2D("h2_var1_var2", "Title;X [unit];Y [unit]",
                               nx, xmin, xmax, ny, ymin, ymax);
```

**In EVENT LOOP:**
```cpp
h2_var1_var2->Fill(var1, var2);
```

### With Cut Stages

```cpp
// Before cuts
TH1D* h_var_before = new TH1D("h_var_before", "Before;X;Counts", 100, 0, 10);

// After cuts
TH1D* h_var_after = new TH1D("h_var_after", "After;X;Counts", 100, 0, 10);

// In loop
h_var_before->Fill(var);
if(passCut){
    h_var_after->Fill(var);
}
```

### Struct-based (multiple variables)

```cpp
struct Var1D {
    std::string key;
    double* v;
    int nbins; double xmin, xmax;
    TH1D* h = nullptr;
};

std::vector<Var1D> vars = {
    {"pt",   &pt,   100, 0, 10,  nullptr},
    {"eta",  &eta,  100, -3, 3,  nullptr},
    {"mass", &mass, 200, 0, 5,   nullptr}
};

// Book
for(auto& v : vars){
    v.h = new TH1D(("h_"+v.key).c_str(), "", v.nbins, v.xmin, v.xmax);
}

// Fill
for(auto& v : vars){
    v.h->Fill(*v.v);
}
```

## Common Binnings

| Variable | Typical Binning |
|----------|-----------------|
| Mass | `200, 0, 5` GeV |
| Momentum | `100, 0, 10` GeV/c |
| θ | `100, 0, 180` deg |
| φ | `100, -180, 180` deg |
| η | `100, -3, 3` |

## Procedure

1. Identify where to add in HISTOGRAMS section
2. Identify where to fill in EVENT LOOP
3. Create edit with `/edit-ifarm`
4. Add to canvas if needed (`/add-canvas`)
