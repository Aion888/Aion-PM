#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/Aion-PM
PY="./aion_env/bin/python"

PM="data/Project_Aion_PM_System.xlsx"
ALIGNED="data/Project_Aion_PM_System_ALIGNED.xlsx"

MIN_CONF="${MIN_CONF:-0.60}"
OVERWRITE="${OVERWRITE:-0}"   # 0 preserve existing, 1 overwrite

# pick best spec
BEST="$(find . -type f -iname "Framework_Directory_Spec*.md" | head -n 1 || true)"
for f in $(find . -type f -iname "Framework_Directory_Spec*.md" 2>/dev/null); do
  if grep -q "00_Executive_Summary" "$f" || grep -q "Technology_Advantage" "$f"; then
    BEST="$f"; break
  fi
done
if [[ -z "${BEST}" ]]; then
  echo "ERROR: Could not find Framework_Directory_Spec*.md"; exit 1
fi

# rebuild Framework_Index.csv if missing or spec newer
if [[ ! -f Framework_Index.csv ]] || [[ "$BEST" -nt Framework_Index.csv ]]; then
  echo "Rebuilding Framework_Index.csv from: $BEST"
  "$PY" - <<'PY'
import re, csv
from pathlib import Path

cands = list(Path(".").rglob("Framework_Directory_Spec*.md"))
best = None
for p in cands:
    t = p.read_text(encoding="utf-8", errors="ignore")
    if ("00_Executive_Summary" in t) or ("Technology_Advantage" in t):
        best = p; break
best = best or (cands[0] if cands else None)
if not best: raise SystemExit("No spec found")

text = best.read_text(encoding="utf-8", errors="ignore").splitlines()
pat = re.compile(r'^(?:├──|└──)\s+(\d{2}_[A-Za-z0-9_]+)\s*/?\s*$')
top = [pat.search(line.strip()).group(1) for line in text if pat.search(line.strip())]

if len(top) < 5:
    cand = re.findall(r'\b(\d{2}_[A-Za-z0-9_]+)\b', "\n".join(text))
    top = [x for x in cand if not x.lower().endswith(("overview","index","master_index","notes"))]

seen=set()
nodes=[n for n in top if not (n in seen or seen.add(n))]

with open("Framework_Index.csv","w",newline="",encoding="utf-8") as f:
    w=csv.writer(f); w.writerow(["Framework_Node"])
    for n in nodes: w.writerow([n])

print("Spec used:", best)
print("Node count:", len(nodes))
print("First 10:", nodes[:10])
PY
else
  echo "Framework_Index.csv up-to-date."
fi

echo "Building ALIGNED..."
"$PY" tools/sync_framework_to_pm.py "$PM"

echo "Building MAPPED..."
if [[ "$OVERWRITE" == "1" ]]; then
  "$PY" tools/realign_framework.py "$ALIGNED" --min_conf "$MIN_CONF" --overwrite
else
  "$PY" tools/realign_framework.py "$ALIGNED" --min_conf "$MIN_CONF"
fi

echo "Summary:"
"$PY" - <<'PY'
from openpyxl import load_workbook
wb = load_workbook("data/Project_Aion_PM_System_ALIGNED_MAPPED.xlsx", data_only=True)
rr = (wb["Review_Roadmap"].max_row-1) if "Review_Roadmap" in wb.sheetnames else 0
tr = (wb["Review_Tickets"].max_row-1) if "Review_Tickets" in wb.sheetnames else 0
print("  Review_Roadmap rows:", max(0, rr))
print("  Review_Tickets rows:", max(0, tr))
PY

echo "Done."
