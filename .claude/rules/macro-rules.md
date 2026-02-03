# ROOT Analysis Macro Rules

This workspace is dedicated to hadron physics analysis using ROOT macros.

Whenever the Agent generates or edits code, it MUST follow the conventions below.

---

## Analysis Philosophy

1. **Physics-first structure**
   - Code structure must reflect the physics workflow
   - Each macro represents one conceptual analysis step

2. **Modularity**
   - Prefer small, single-purpose macros (`study*.C`, `select*.C`)
   - Reuse shared logic via common include files
   - Do not create monolithic "do everything" macros

3. **Explicitness over cleverness**
   - Favor readable loops and named variables over compact tricks
   - Avoid hidden behavior and magic numbers
   - All cuts and ranges must be visible in code or printed logs

4. **Reproducibility**
   - Outputs must be deterministic
   - Every macro should be runnable independently
   - Important parameters must be printed or logged

---

## Coding Style Rules

- Use explicit namespaces for shared parameters

- Prefer small structs for analysis units:
  ```cpp
  struct Var1D {
    std::string key;
    double* v;
    TH1Config cfg;
    TH1* h = nullptr;
  };
  ```

- Histograms:
  - Always define binning explicitly
  - Use meaningful names (`h_pt`, `h_mass`, `h_eta`, etc.)
  - Never rely on anonymous or implicit histograms

- Output format:
  - Numerical summaries must be CSV-like:
    ```
    step, n_total, n_after, efficiency
    cut1, 124532, 93211, 0.749
    ```

- Fitting:
  - Fit results must be stored in structs or return objects
  - Never hide results inside local scopes only

---

## Macro Execution Rules

1. **Run from the macro directory**
   - All macros are runnable from the macro directory
   - Do not run macros from arbitrary working directories

2. **Execution command**
   ```bash
   root -b -q 'macroName.C("param.json")'
   ```

3. **Batch mode required**
   - Always use `gROOT->SetBatch(true)` for remote execution
   - No GUI or display available on remote servers

4. **No compilation** (unless needed)
   - Avoid `+` compilation and ACLiC unless required
   - Interpreted mode is more portable

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Study | `study<Topic>.C` | `studyAcceptance.C` |
| Selection | `select<What>.C` | `selectGoodEvents.C` |
| Calculation | `calc<What>.C` | `calcEfficiency.C` |
| Application | `apply<What>.C` | `applyCorrection.C` |
| Comparison | `compare<What>.C` | `compareDataMC.C` |
| Check/Debug | `check<What>.C` | `checkNormalization.C` |

---

## Histogram Naming

| Type | Pattern | Example |
|------|---------|---------|
| 1D | `h_<variable>` | `h_pt`, `h_mass` |
| 2D | `h2_<var1>_<var2>` | `h2_pt_eta` |
| Per-bin | `h_<var>_bin<N>` | `h_mass_bin0` |
| Generated (MC) | `h_<var>_gen` | `h_pt_gen` |
| Reconstructed | `h_<var>_rec` | `h_pt_rec` |

---

## Output File Naming

```
<macroName>_<dataset>_<config>.root
<macroName>_<dataset>_<config>.pdf
```

Examples:
- `studyAcceptance_data_run1.root`
- `calcEfficiency_mc_nominal.pdf`
