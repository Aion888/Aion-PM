#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/Aion-PM
PY="./aion_env/bin/python"

MAPPED="data/Project_Aion_PM_System_ALIGNED_MAPPED.xlsx"
MANUAL="data/Project_Aion_PM_System_ALIGNED_MAPPED_MANUAL.xlsx"
CSV="tools/framework_manual_map.csv"

# 1) (re)generate manual map CSV from review sheets
"$PY" - <<'PY'
import csv
from pathlib import Path
from openpyxl import load_workbook

WB_IN = Path("data/Project_Aion_PM_System_ALIGNED_MAPPED.xlsx")
CSV_OUT = Path("tools/framework_manual_map.csv")

wb = load_workbook(WB_IN, data_only=True)

def norm(s): return (s or "").strip().lower()
def hmap(ws):
    m={}
    for c in range(1, ws.max_column+1):
        v = ws.cell(1,c).value
        if isinstance(v,str) and v.strip():
            m[norm(v)] = c
    return m
def pick(h, keys):
    for k in keys:
        if k in h: return h[k]
    return None
def review_rows(ws_review):
    rows=[]
    for r in range(2, ws_review.max_row+1):
        rr = ws_review.cell(r,1).value
        if rr is None: 
            continue
        try: rr = int(rr)
        except: continue
        cur = (ws_review.cell(r,2).value or "")
        sug = (ws_review.cell(r,3).value or "")
        conf = ws_review.cell(r,4).value or 0
        top3 = (ws_review.cell(r,5).value or "")
        rows.append((rr, str(cur).strip(), str(sug).strip(), float(conf or 0.0), str(top3)))
    return rows
def trunc(x,n=200):
    x = "" if x is None else str(x)
    x = x.replace("\n"," ").strip()
    return x if len(x)<=n else x[:n-1]+"…"

out_rows=[]

if "Review_Roadmap" in wb.sheetnames and "02_Roadmap" in wb.sheetnames:
    ws_r = wb["Review_Roadmap"]; ws_b = wb["02_Roadmap"]; hb = hmap(ws_b)
    c_id   = pick(hb, ["epic id","epic_id","epicid","id"])
    c_name = pick(hb, ["epic","epic name","epic_title","title"])
    c_goal = pick(hb, ["goal","objective","outcome","description","details","summary"])
    for rr,cur,sug,conf,top3 in review_rows(ws_r):
        rid  = ws_b.cell(rr, c_id).value if c_id else ""
        name = ws_b.cell(rr, c_name).value if c_name else ""
        info = ws_b.cell(rr, c_goal).value if c_goal else ""
        final = cur if cur else sug
        out_rows.append(["roadmap","02_Roadmap",rr,trunc(rid,60),trunc(name,120),trunc(info,200),cur,sug,round(conf,3),trunc(top3,220),final])

if "Review_Tickets" in wb.sheetnames and "04_Tickets" in wb.sheetnames:
    ws_r = wb["Review_Tickets"]; ws_b = wb["04_Tickets"]; hb = hmap(ws_b)
    c_id   = pick(hb, ["ticket id","ticket_id","ticketid","id"])
    c_name = pick(hb, ["ticket","title","summary","task","story"])
    c_goal = pick(hb, ["description","details","notes","goal"])
    for rr,cur,sug,conf,top3 in review_rows(ws_r):
        rid  = ws_b.cell(rr, c_id).value if c_id else ""
        name = ws_b.cell(rr, c_name).value if c_name else ""
        info = ws_b.cell(rr, c_goal).value if c_goal else ""
        final = cur if cur else sug
        out_rows.append(["tickets","04_Tickets",rr,trunc(rid,60),trunc(name,120),trunc(info,200),cur,sug,round(conf,3),trunc(top3,220),final])

CSV_OUT.parent.mkdir(parents=True, exist_ok=True)
with CSV_OUT.open("w", newline="", encoding="utf-8") as f:
    w=csv.writer(f)
    w.writerow(["scope","sheet","row","id","title","info","current_framework_node","suggested","confidence","top3","framework_node_final"])
    w.writerows(out_rows)

print("Wrote:", CSV_OUT)
print("Rows :", len(out_rows))
PY

echo "Manual map CSV ready: $CSV"
echo "Edit 'framework_node_final' if needed, then run this script again to apply."

# 2) Apply manual map -> MANUAL workbook
"$PY" tools/apply_framework_manual_map.py "$MAPPED" "$CSV" "$MANUAL"

# 3) Sanity: meaningful blanks
"$PY" - <<'PY'
from openpyxl import load_workbook

wb = load_workbook("data/Project_Aion_PM_System_ALIGNED_MAPPED_MANUAL.xlsx", data_only=True)

def norm(x):
    if x is None: return ""
    return str(x).replace("\n"," ").strip()

def headers(ws):
    m={}
    for c in range(1, ws.max_column+1):
        v = ws.cell(1,c).value
        if isinstance(v,str) and v.strip():
            m[v.strip().lower()] = c
    return m

def scan(sheet):
    ws = wb[sheet]
    h = headers(ws)
    c_node = h.get("framework_node")
    if not c_node:
        print(f"{sheet}: no Framework_Node column")
        return
    interesting = [h[k] for k in ["epic id","ticket id","id","epic","title","ticket","summary","goal","description","details","notes"] if k in h]
    found=0
    for r in range(2, ws.max_row+1):
        node = norm(ws.cell(r,c_node).value)
        if node:
            continue
        has_content = any(norm(ws.cell(r,c).value) for c in interesting) if interesting else False
        if has_content:
            found += 1
            print(f"  {sheet} row {r} has content but blank Framework_Node")
    if found==0:
        print(f"{sheet}: meaningful blanks = none")

for s in ["02_Roadmap","04_Tickets"]:
    if s in wb.sheetnames:
        scan(s)
PY

echo "Final workbook: $MANUAL"
