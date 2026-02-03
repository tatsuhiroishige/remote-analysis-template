# add-canvas

Add a new canvas page to PDF output.

## Usage
```
/add-canvas <macro> <layout> [histograms]
```

## Examples
```
/add-canvas analysis 2x2 "h_pt, h_eta, h_phi, h_mass"
/add-canvas study 1x1 h_result
```

## Code Templates

### Single Plot

```cpp
TCanvas* c1 = new TCanvas("c1", "Title", 1200, 800);
h_var->Draw();
c1->Print(pic_file.c_str());
```

### Grid Layout (2x2)

```cpp
TCanvas* c1 = new TCanvas("c1", "Title", 1200, 800);
c1->Divide(2, 2);

c1->cd(1); h_var1->Draw();
c1->cd(2); h_var2->Draw();
c1->cd(3); h_var3->Draw();
c1->cd(4); h_var4->Draw();

c1->Print(pic_file.c_str());
```

### Multi-Page PDF

```cpp
// Open PDF (first page)
TCanvas* c1 = new TCanvas("c1", "Results", 1200, 800);
c1->Print((pic_file + "(").c_str());  // "(" opens

// Page 1
h_var1->Draw();
c1->Print(pic_file.c_str());

// Page 2
c1->Clear();
c1->Divide(2, 2);
c1->cd(1); h_a->Draw();
c1->cd(2); h_b->Draw();
c1->cd(3); h_c->Draw();
c1->cd(4); h_d->Draw();
c1->Print(pic_file.c_str());

// Close PDF (last page)
c1->Clear();
h_var2->Draw();
c1->Print((pic_file + ")").c_str());  // ")" closes
```

### 2D Histogram

```cpp
c1->cd(1);
h2_var->Draw("COLZ");  // Color map
gPad->SetRightMargin(0.15);  // Space for color bar
```

### With Legend

```cpp
h_data->SetLineColor(kBlack);
h_mc->SetLineColor(kRed);
h_data->Draw();
h_mc->Draw("same");

TLegend* leg = new TLegend(0.7, 0.7, 0.9, 0.9);
leg->AddEntry(h_data, "Data", "l");
leg->AddEntry(h_mc, "MC", "l");
leg->Draw();
```

## Common Layouts

| Layout | Divide | Use Case |
|--------|--------|----------|
| 1x1 | - | Single plot |
| 2x1 | `(2,1)` | Comparison |
| 2x2 | `(2,2)` | 4 variables |
| 3x2 | `(3,2)` | 6 variables |

## Procedure

1. Find CANVAS section in macro
2. Identify where to add new page
3. Check if using multi-page pattern `(` `)`
4. Create edit with `/edit-ifarm`
