# Analysis Macro Creation Guide

Instructions for creating ROOT analysis macros.

---

## Macro Template

```cpp
#ifndef MACRONAME_C
#define MACRONAME_C

/**
 * @brief One-line description
 * @param param_file Path to JSON parameter file (optional)
 */
void macroName(std::string param_file="../param/params.json"){

    // ========================================================
    // ===                 SETUP                            ===
    // ========================================================

    gROOT->SetBatch(true);  // Required for remote execution
    gBenchmark->Start("timer");

    // ========================================================
    // ===             HISTOGRAM DEFINITIONS                ===
    // ========================================================

    // Always use explicit binning
    TH1D* h_pt = new TH1D("h_pt", "p_{T};p_{T} [GeV/c];Counts", 100, 0, 10);
    TH1D* h_mass = new TH1D("h_mass", "Mass;M [GeV/c^{2}];Counts", 200, 0, 5);

    // ========================================================
    // ===                 EVENT LOOP                       ===
    // ========================================================

    // Event counters
    long n0 = 0, n1 = 0, n2 = 0;

    // Input
    TChain* chain = new TChain("tree");
    chain->Add("/path/to/data/*.root");

    double pt, mass;
    chain->SetBranchAddress("pt", &pt);
    chain->SetBranchAddress("mass", &mass);

    Long64_t nEntries = chain->GetEntries();
    std::cout << "Processing " << nEntries << " entries" << std::endl;

    for(Long64_t i = 0; i < nEntries; i++){
        chain->GetEntry(i);
        n0++;

        // Progress indicator
        if(n0 % 100000 == 0){
            std::cout << "Processing: " << n0 << "/" << nEntries << "\r" << std::flush;
        }

        // === Selection cuts ===
        if(pt < 0.5) continue;
        n1++;

        // === Fill histograms ===
        h_pt->Fill(pt);
        h_mass->Fill(mass);
        n2++;
    }

    // ========================================================
    // ===              EVENT COUNT SUMMARY                 ===
    // ========================================================

    std::cout << "\n";
    std::cout << "step, n_total, n_after, efficiency" << std::endl;
    std::cout << "Initial, " << n0 << ", " << n0 << ", 1.000" << std::endl;
    std::cout << "pt_cut, " << n0 << ", " << n1 << ", " << (double)n1/n0 << std::endl;
    std::cout << "Final, " << n1 << ", " << n2 << ", " << (double)n2/n1 << std::endl;

    // ========================================================
    // ===                    OUTPUT                        ===
    // ========================================================

    // PDF Output
    TCanvas* c1 = new TCanvas("c1", "Results", 1200, 800);
    c1->Divide(2, 1);
    c1->cd(1); h_pt->Draw();
    c1->cd(2); h_mass->Draw();
    c1->Print("../pic/macroName_output.pdf");

    // ROOT Output
    TFile* outFile = new TFile("../root/macroName_output.root", "RECREATE");
    h_pt->Write();
    h_mass->Write();
    outFile->Close();
    std::cout << "Output saved" << std::endl;

    gBenchmark->Show("timer");
}

#endif
```

---

## Histogram Struct Pattern

For multiple similar histograms:

```cpp
struct TH1Config {
    std::string name, title, xaxis, yaxis;
    int nbins;
    double xmin, xmax;
};

struct Var1D {
    std::string key;
    double* v;
    TH1Config cfg;
    TH1* h = nullptr;
};

// Define variables
std::vector<Var1D> vars = {
    {"pt",   &pt,   {"h_pt",   "p_{T}", "p_{T} [GeV/c]", "Counts", 100, 0, 10}, nullptr},
    {"mass", &mass, {"h_mass", "Mass",  "M [GeV/c^{2}]", "Counts", 200, 0, 5},  nullptr}
};

// Book histograms
for(auto& var : vars){
    var.h = new TH1D(var.cfg.name.c_str(), var.cfg.title.c_str(),
                     var.cfg.nbins, var.cfg.xmin, var.cfg.xmax);
}

// Fill in event loop
for(auto& var : vars){
    var.h->Fill(*var.v);
}
```

---

## Parameter File (Optional)

JSON format in `param/params_<macroName>.json`:

```json
{
    "flags": {
        "pdf_flag": true,
        "batch_flag": true
    },
    "data": {
        "input_path": "/path/to/data/*.root",
        "tree_name": "tree"
    },
    "cuts": {
        "pt_min": 0.5,
        "eta_max": 2.5
    },
    "output": {
        "root_name": "analysis_output",
        "pic_name": "analysis_plots"
    }
}
```

---

## Common Functions

Create `commonFunctions.C` for shared utilities:

```cpp
// File existence check
bool FileExists(const std::string& path){
    std::ifstream f(path);
    return f.good();
}

// Print fit results
void PrintFitResults(TF1* f){
    std::cout << "Chi2/NDF: " << f->GetChisquare() / f->GetNDF() << std::endl;
    for(int i = 0; i < f->GetNpar(); i++){
        std::cout << f->GetParName(i) << ": "
                  << f->GetParameter(i) << " +/- "
                  << f->GetParError(i) << std::endl;
    }
}
```

---

## Execution Checklist

Before running a new macro:

- [ ] Macro has `#ifndef` / `#define` / `#endif` guards
- [ ] Uses `gROOT->SetBatch(true)` for remote execution
- [ ] Runs from `macro/` directory
- [ ] All cuts are explicit (no magic numbers)
- [ ] Event counts printed in CSV format
- [ ] Output paths are correct (`../pic/`, `../root/`)
