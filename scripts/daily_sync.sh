#!/usr/bin/env bash
set -euo pipefail
python scripts/update_framework_spec_trees.py
python scripts/pm_drift_check.py
echo "✅ Daily sync complete"
