#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/Aion-PM

SRC="data/Project_Aion_PM_System_ALIGNED_MAPPED_MANUAL.xlsx"
DST="data/Project_Aion_PM_System.xlsx"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: Missing $SRC (run ./tools/pm_finalize.sh first)"
  exit 1
fi

ts=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$ts"

# backup current official if present
if [[ -f "$DST" ]]; then
  cp -v "$DST" "backups/$ts/Project_Aion_PM_System.xlsx"
fi

# backup artifacts too (useful for audit/revert)
cp -v "Framework_Index.csv" "backups/$ts/" 2>/dev/null || true
cp -v "tools/framework_manual_map.csv" "backups/$ts/" 2>/dev/null || true
cp -v "data/Project_Aion_PM_System_ALIGNED.xlsx" "backups/$ts/" 2>/dev/null || true
cp -v "data/Project_Aion_PM_System_ALIGNED_MAPPED.xlsx" "backups/$ts/" 2>/dev/null || true
cp -v "$SRC" "backups/$ts/" 2>/dev/null || true

# promote
cp -v "$SRC" "$DST"

echo "✅ Promoted to official: $DST"
echo "🧾 Backup saved in: backups/$ts"
