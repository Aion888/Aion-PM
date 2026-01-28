from __future__ import annotations
from pathlib import Path
import re
import subprocess

BASE = Path("Project_Aion/01_Project_Framework/00_Master_Index")
SPEC_DIR = BASE / "Framework_Directory_Spec"

BEGIN_RE = re.compile(r"<!-- TREE:BEGIN -->")
END_RE   = re.compile(r"<!-- TREE:END -->")

# Map realm spec filename -> real folder path in repo
REALM_PATHS = {
    "01_Project_Framework.md": "Project_Aion/01_Project_Framework",
    "02_Glass_Cockpit_GUI.md": "Project_Aion/02_Glass_Cockpit_GUI",
    "03_Artifacts.md": "Project_Aion/03_Artifacts",
    "04_Admin_Automation_AWACS.md": "Project_Aion/04_Admin_Automation_AWACS",
    "05_IT_Infrastructure.md": "Project_Aion/05_IT_Infrastructure",
    "06_Databases.md": "Project_Aion/06_Databases",
    "07_Expert_Systems.md": "Project_Aion/07_Expert_Systems",
    # These may differ in your repo; adjust if needed:
    "08_Modelling_Feature_Design_and_Engineering.md": "Project_Aion/08_Modelling_Feature_Design_and_Engineering_Principles",
    "09_ML_AI_Systems.md": "Project_Aion/09_ML_AI_Systems",
    "10_Model_Simulation_Backtesting.md": "Project_Aion/10_Model_Simulation_Backtesting",
    "11_Trading_Strategies.md": "Project_Aion/11_Trading_Strategies",
    "12_Trading_Engines.md": "Project_Aion/12_Trading_Engines",
    "13_Business_Intelligence.md": "Project_Aion/13_Business_Intelligence",
}

# Depth per realm (keep small for readability; databases slightly deeper)
DEPTH = {
    "06_Databases.md": 5
}

def have_tree() -> bool:
    try:
        subprocess.check_output(["tree", "--version"], text=True)
        return True
    except Exception:
        return False

def snapshot(path: Path, depth: int) -> str:
    if not path.exists():
        return f"```text\n(MISSING PATH: {path})\n```"

    if have_tree():
        # include files too (important for realms with .md docs)
        out = subprocess.check_output(["tree", "-L", str(depth), str(path)], text=True)
    else:
        cmd = f'find "{path}" -maxdepth {depth} -print | sort'
        out = subprocess.check_output(["bash", "-lc", cmd], text=True)

    return "```text\n" + out.rstrip() + "\n```"

def update(fp: Path) -> bool:
    name = fp.name
    realm_path = Path(REALM_PATHS.get(name, ""))
    depth = DEPTH.get(name, 4)

    txt = fp.read_text(encoding="utf-8", errors="ignore")

    if "<!-- TREE:BEGIN -->" not in txt or "<!-- TREE:END -->" not in txt:
        return False

    block = snapshot(Path(realm_path), depth)

    # Replace everything between markers
    start = txt.find("<!-- TREE:BEGIN -->")
    end = txt.find("<!-- TREE:END -->", start)
    if end == -1:
        return False

    new_txt = txt[:start] + "<!-- TREE:BEGIN -->\n" + block + "\n" + txt[end:]
    if new_txt != txt:
        fp.write_text(new_txt, encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for fp in sorted(SPEC_DIR.glob("*.md")):
        if update(fp):
            changed += 1
            print("Updated:", fp)
    print("Done. Files updated:", changed)

if __name__ == "__main__":
    main()
