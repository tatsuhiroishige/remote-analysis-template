# check-root

Inspect ROOT file contents on the remote server.

## Usage
```
/check-root <filename> [command]
```

## Examples
```
/check-root output.root
/check-root analysis.root "tree->Print()"
/check-root results.root "h_pt->GetEntries()"
```

## Instructions

### 1. Create inspection script

```bash
cat > scripts/check_root.sh << 'EOF'
#!/bin/bash
cd $WORKDIR/root
root -b -q -e '
TFile* f = TFile::Open("<filename>");
f->ls();
// Additional commands here
f->Close();
'
EOF
```

### 2. Common inspection commands

**List contents:**
```cpp
f->ls();
```

**Print tree structure:**
```cpp
TTree* t = (TTree*)f->Get("tree");
t->Print();
```

**Show branches:**
```cpp
t->GetListOfBranches()->Print();
```

**Get entries:**
```cpp
std::cout << "Entries: " << t->GetEntries() << std::endl;
```

**Histogram stats:**
```cpp
TH1* h = (TH1*)f->Get("h_pt");
h->Print("all");
```

**Draw quick plot:**
```cpp
TH1* h = (TH1*)f->Get("h_mass");
TCanvas* c = new TCanvas();
h->Draw();
c->Print("../pic/quick_check.pdf");
```

### 3. Execute

```bash
scp scripts/check_root.sh $HOST:~/tmp/
ssh $HOST "bash ~/tmp/check_root.sh"
```

### 4. Report to user

- List of objects in file
- Number of entries (for trees)
- Key histogram statistics
- Any errors or missing objects

## Notes

- File path is relative to `$WORKDIR/root/`
- Use full path for files in other locations
- Can also check local ROOT files if downloaded
