import os
import time

AION_UI_VERSION = time.strftime('%Y%m%d') + '_V01'

import re
import hashlib
import pandas as pd
from datetime import datetime
from dash import Dash, dcc, html, Input, Output, State, no_update
from dash.dash_table import DataTable

EXCEL_FILE = "Project_Aion_PM_System.xlsx"
TICKETS_CSV = "tickets_live.csv"
DECISIONS_CSV = "decisions_live.csv"
EXPORT_TICKETS_SHEET = "04_Tickets_LIVE"
EXPORT_DECISIONS_SHEET = "06_Decisions_LIVE"

DEFAULT_STATUSES = ["To Do", "In Progress", "Blocked", "Done"]
DEFAULT_PRIORITIES = ["High", "Medium", "Low"]

# ---------- Helpers ----------
def now_str():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def today_yyyymmdd():
    return datetime.now().strftime("%Y%m%d")

def df_hash(df: pd.DataFrame) -> str:
    s = df.fillna("").astype(str).to_csv(index=False)
    return hashlib.md5(s.encode("utf-8")).hexdigest()

def first_existing_column(df, candidates):
    cols_lower = {c.lower(): c for c in df.columns}
    for cand in candidates:
        if cand.lower() in cols_lower:
            return cols_lower[cand.lower()]
    return None

def ensure_columns(df: pd.DataFrame, required_cols):
    for c in required_cols:
        if c not in df.columns:
            df[c] = ""
    return df

def safe_unique(df, col):
    if not col or col not in df.columns:
        return []
    vals = [str(v).strip() for v in df[col].fillna("").tolist()]
    vals = [v for v in vals if v]
    seen, out = set(), []
    for v in vals:
        if v not in seen:
            seen.add(v)
            out.append(v)
    return out

def infer_ticket_id_column(df):
    return first_existing_column(df, ["Ticket ID", "Ticket", "TicketID", "ID", "Key", "Issue Key", "Issue"]) or "Ticket ID"

def next_ticket_id(df, id_col):
    if not id_col or id_col not in df.columns:
        return "T-0001"
    vals = [str(v).strip() for v in df[id_col].fillna("").tolist()]

    nums = []
    for v in vals:
        m = re.search(r'([A-Za-z]+)[-_ ]?(\d+)$', v)
        if m and m.group(1).upper().startswith("T"):
            nums.append(int(m.group(2)))
    if nums:
        return f"T-{max(nums)+1:04d}"
    return "T-0001"

def dropdown_map(df, col, defaults=None):
    if not col or col not in df.columns:
        return None
    values = safe_unique(df, col)
    if defaults:
        for d in defaults[::-1]:
            if d not in values:
                values.insert(0, d)
    return {col: {"options": [{"label": v, "value": v} for v in values]}}

def safe_export_df_to_excel(sheet_name, df: pd.DataFrame) -> None:
    with pd.ExcelWriter(EXCEL_FILE, engine="openpyxl", mode="a", if_sheet_exists="replace") as writer:
        df.to_excel(writer, sheet_name=sheet_name, index=False)

# --- Date formatting: Start / Due / Created / Updated -> YYYYMMDD (no time) ---
DATE_KEYS = ["start", "due", "created", "updated"]

def is_date_col(colname: str) -> bool:
    s = (colname or "").strip().lower()
    # match exact or common variants like "Start Date", "Due_Date", "Created At", etc.
    return any(k == s or s.startswith(k) or s.endswith(k) or f"{k} " in s or f" {k}" in s or f"{k}_" in s or f"_{k}" in s for k in DATE_KEYS)

def normalize_dates(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    for col in df.columns:
        if not is_date_col(col):
            continue
        raw = df[col].fillna("").astype(str).str.strip()

        # Remove trailing time if present
        raw = raw.str.replace(r"\s+00:00:00$", "", regex=True)

        # Try parse -> format YYYYMMDD
        dt = pd.to_datetime(raw, errors="coerce", dayfirst=False)
        formatted = dt.dt.strftime("%Y%m%d")

        # Where parsing worked, use formatted; else keep cleaned raw (and strip separators if it's already date-ish)
        cleaned_raw = raw.str.replace("-", "", regex=False).str.replace("/", "", regex=False)
        df[col] = formatted.where(dt.notna(), cleaned_raw).replace("NaT", "")

        # Final tidy: blanks stay blank
        df[col] = df[col].fillna("").astype(str).str.strip()
    return df

# ---------- Loaders ----------
def load_charter():
    xls = pd.ExcelFile(EXCEL_FILE)
    df = pd.read_excel(xls, "01_Project_Charter", header=None)
    c = df.iloc[:, :2].copy()
    c.columns = ["Field", "Value"]
    c = c.dropna(how="all")
    c["Field"] = c["Field"].fillna("").astype(str).str.strip()
    c["Value"] = c["Value"].fillna("").astype(str).str.strip()
    c = c[(c["Field"] != "") | (c["Value"] != "")]
    return c

def load_roadmap():
    xls = pd.ExcelFile(EXCEL_FILE)
    return pd.read_excel(xls, "02_Roadmap", header=3).fillna("")

def load_tickets_seed_from_excel():
    xls = pd.ExcelFile(EXCEL_FILE)
    return pd.read_excel(xls, "04_Tickets", header=3).fillna("")

def load_tickets():
    if os.path.exists(TICKETS_CSV):
        return pd.read_csv(TICKETS_CSV).fillna("")
    return load_tickets_seed_from_excel()

def load_decisions_seed_from_excel():
    try:
        xls = pd.ExcelFile(EXCEL_FILE)
        return pd.read_excel(xls, "06_Decisions_Log", header=3).fillna("")
    except Exception:
        return pd.DataFrame()

def load_decisions():
    if os.path.exists(DECISIONS_CSV):
        return pd.read_csv(DECISIONS_CSV).fillna("")
    return load_decisions_seed_from_excel().fillna("")

# ---------- Initial data ----------
charter_tbl = load_charter()
roadmap_df = load_roadmap()

tickets_df = load_tickets()
id_col = infer_ticket_id_column(tickets_df)
status_col = first_existing_column(tickets_df, ["Status"]) or "Status"
priority_col = first_existing_column(tickets_df, ["Priority"]) or "Priority"
owner_col = first_existing_column(tickets_df, ["Owner", "Assignee"]) or "Owner"
epic_col = first_existing_column(tickets_df, ["Epic", "Epic ID", "EpicID"]) or "Epic"
title_col = first_existing_column(tickets_df, ["Title", "Summary", "Task", "Ticket Title"]) or "Title"

tickets_df = ensure_columns(tickets_df, [id_col, title_col, status_col, priority_col, owner_col, epic_col]).fillna("")
tickets_df[status_col] = tickets_df[status_col].replace("", "To Do")
tickets_df = normalize_dates(tickets_df)

decisions_df = load_decisions()
decisions_df = ensure_columns(decisions_df, ["Date", "Decision", "Rationale", "Owner", "Link"]).fillna("")

dropdowns = {}
d = dropdown_map(tickets_df, status_col, defaults=DEFAULT_STATUSES)
if d: dropdowns.update(d)
d = dropdown_map(tickets_df, priority_col, defaults=DEFAULT_PRIORITIES)
if d: dropdowns.update(d)
d = dropdown_map(tickets_df, owner_col)
if d: dropdowns.update(d)
d = dropdown_map(tickets_df, epic_col)
if d: dropdowns.update(d)

# ---------- UI helpers ----------
BASE_STYLE = {"padding":"16px","fontFamily":"Arial"}

DT_STYLE_CELL = {
    "padding":"6px",
    "whiteSpace":"normal",
    "height":"auto",
    "fontFamily":"Arial",
    "fontSize":"14px",
}

def kpi_cards(df):
    total = len(df)
    status_counts = df[status_col].value_counts() if status_col in df.columns else pd.Series(dtype=int)
    prio_counts = df[priority_col].value_counts() if priority_col in df.columns else pd.Series(dtype=int)

    def card(title, value):
        return html.Div(
            style={"padding":"12px","border":"1px solid #ddd","borderRadius":"12px","minWidth":"160px",
                   "boxShadow":"0 1px 2px rgba(0,0,0,0.05)"},
            children=[html.Div(title, style={"fontSize":"12px","opacity":0.75, "fontFamily":"Arial"}),
                      html.Div(str(value), style={"fontSize":"22px","fontWeight":700, "fontFamily":"Arial"})],
        )

    cards = [card("Total tickets", total)]
    for k, v in status_counts.head(3).items():
        cards.append(card(f"Status: {k}", int(v)))
    for k, v in prio_counts.head(2).items():
        cards.append(card(f"Priority: {k}", int(v)))
    return html.Div(style={'position':'relative', "display":"flex","gap":"10px","flexWrap":"wrap","margin":"10px 0"}, children=cards)

def kanban_subset(df, status_name):
    show_cols = [c for c in [id_col, title_col, owner_col, priority_col, epic_col] if c in df.columns]
    df2 = df[df[status_col] == status_name] if status_col in df.columns else df.iloc[0:0]
    return df2[show_cols].to_dict("records")

# ---------- App ----------
app = Dash(__name__, prevent_initial_callbacks="initial_duplicate")
app.title = "Project Aion - PM System"

# Force Arial at page level too
app.index_string = """
<!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            body { font-family: Arial, sans-serif; }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
"""

app.layout = html.Div(
    style=BASE_STYLE,
    children=[
        html.Img(
            src=app.get_asset_url('logos/aion_logo.png'),
            style={
                'position': 'absolute',
                'top': '14px',
                'right': '18px',
                'height': '56px',
                'width': '56px',
                'opacity': 0.98,
                'display': 'block',
            },
        ),

        html.Div(
            AION_UI_VERSION,
            style={
                'position': 'absolute',
                'top': '74px',
                'right': '18px',
                'fontSize': '12px',
                'fontWeight': 800,
                'letterSpacing': '0.06em',
                'color': '#6b7280',
                'textAlign': 'right',
                'lineHeight': '1',
            },
        ),


        html.H2("Project Aion — PM System", style={"fontFamily":"Arial"}),
        html.Hr(),

        dcc.Store(id="tickets_store", data=tickets_df.to_dict("records")),
        dcc.Store(id="decisions_store", data=decisions_df.to_dict("records")),
        dcc.Store(id="tickets_saved_hash", data=df_hash(tickets_df)),
        dcc.Store(id="decisions_saved_hash", data=df_hash(decisions_df)),
        dcc.Interval(id="autosave", interval=60_000, n_intervals=0),

        dcc.Tabs([
            dcc.Tab(label="Overview", children=[
                DataTable(
                    data=charter_tbl.to_dict("records"),
                    columns=[{"name":"Field","id":"Field"},{"name":"Value","id":"Value"}],
                    page_size=25,
                    style_table={"overflowX":"auto"},
                    style_cell=DT_STYLE_CELL,
                                    style_header={"fontWeight":"700","fontFamily":"Arial","textAlign":"center"},
                    style_cell_conditional=[
                        {"if":{"column_id":"Field"}, "width":"21%", "minWidth":"220px", "whiteSpace":"nowrap", "textAlign":"center"},
                        {"if":{"column_id":"Value"}, "width":"79%", "textAlign":"center"},
                    ],
                    style_data_conditional=[
                        {"if":{"column_id":"Field"}, "fontWeight":"700"},
                    ],
                    )
            ]),

            dcc.Tab(label="Tickets", children=[
                html.Div(id="tickets_kpis"),

                html.Div(style={"display":"flex","gap":"8px","margin":"8px 0","flexWrap":"wrap"}, children=[
                    html.Button("Save Tickets", id="btn_save_tickets"),
                    html.Button("Reload Tickets", id="btn_reload_tickets"),
                    html.Button("Export Tickets to Excel", id="btn_export_tickets"),
                    html.Div(id="tickets_dirty", style={"padding":"6px 10px","border":"1px solid #ddd","borderRadius":"10px", "fontFamily":"Arial"}),
                ]),
                html.Div(id="tickets_msg", style={"margin":"8px 0","fontFamily":"Arial"}),

                html.Div(
                    style={"border":"1px solid #ddd","borderRadius":"12px","padding":"10px","marginBottom":"10px"},
                    children=[
                        html.Div("New Ticket", style={"fontWeight":800,"marginBottom":"8px","fontFamily":"Arial"}),
                        html.Div(style={"display":"flex","gap":"10px","flexWrap":"wrap"}, children=[
                            dcc.Input(id="new_title", placeholder="Title", style={"width":"360px", "padding":"8px", "fontFamily":"Arial"}),
                            dcc.Dropdown(id="new_status", options=[{"label": s, "value": s} for s in DEFAULT_STATUSES],
                                         value="To Do", style={"minWidth":"200px", "fontFamily":"Arial"}),
                            dcc.Dropdown(id="new_priority", options=[{"label": p, "value": p} for p in DEFAULT_PRIORITIES],
                                         value="Medium", style={"minWidth":"200px", "fontFamily":"Arial"}),
                            dcc.Input(id="new_owner", placeholder="Owner", style={"width":"200px","padding":"8px","fontFamily":"Arial"}),
                            dcc.Input(id="new_epic", placeholder="Epic", style={"width":"200px","padding":"8px","fontFamily":"Arial"}),
                            html.Button("Add Ticket", id="btn_add_ticket"),
                        ]),
                        html.Div(id="new_ticket_msg", style={"marginTop":"8px","fontFamily":"Arial"}),
                    ]
                ),

                html.Div(style={"display":"flex","gap":"12px"}, children=[
                    html.Div(style={"flex":3}, children=[
                        DataTable(
                            id="tickets_tbl",
                            data=[],
                            columns=[{"name": c, "id": c, "editable": True} for c in tickets_df.columns],
                            editable=True,
                            row_deletable=True,
                            dropdown=dropdowns,
                            page_size=18,
                            filter_action="native",
                            sort_action="native",
                            style_table={"overflowX":"auto"},
                            style_cell=DT_STYLE_CELL,
                        )
                    ]),
                    html.Div(style={"flex":1,"border":"1px solid #ddd","borderRadius":"12px","padding":"10px"}, children=[
                        html.Div("Ticket detail", style={"fontWeight":800,"marginBottom":"8px","fontFamily":"Arial"}),
                        html.Pre(id="ticket_detail", style={"whiteSpace":"pre-wrap","margin":0, "fontFamily":"Arial"}),
                    ]),
                ]),
            ]),

            dcc.Tab(label="Kanban", children=[
                html.Div(style={"display":"flex","gap":"10px","margin":"10px 0","flexWrap":"wrap"}, children=[
                    dcc.Dropdown(id="move_target_status",
                                 options=[{"label": s, "value": s} for s in DEFAULT_STATUSES],
                                 value="In Progress", style={"minWidth":"220px", "fontFamily":"Arial"}),
                    html.Button("Move selected → target", id="btn_move_selected"),
                    html.Div(id="kanban_msg", style={"marginLeft":"10px","fontFamily":"Arial"}),
                ]),
                html.Div(style={"display":"flex","gap":"12px","flexWrap":"wrap"}, children=[
                    html.Div(style={"flex":1,"minWidth":"260px","border":"1px solid #ddd","borderRadius":"12px","padding":"10px"}, children=[
                        html.Div("To Do", style={"fontWeight":800,"fontFamily":"Arial"}),
                        DataTable(id="kanban_todo", data=[], columns=[{"name": c, "id": c} for c in [id_col, title_col, owner_col, priority_col, epic_col] if c in tickets_df.columns],
                                  row_selectable="multi", page_size=10, style_cell=DT_STYLE_CELL)
                    ]),
                    html.Div(style={"flex":1,"minWidth":"260px","border":"1px solid #ddd","borderRadius":"12px","padding":"10px"}, children=[
                        html.Div("In Progress", style={"fontWeight":800,"fontFamily":"Arial"}),
                        DataTable(id="kanban_ip", data=[], columns=[{"name": c, "id": c} for c in [id_col, title_col, owner_col, priority_col, epic_col] if c in tickets_df.columns],
                                  row_selectable="multi", page_size=10, style_cell=DT_STYLE_CELL)
                    ]),
                    html.Div(style={"flex":1,"minWidth":"260px","border":"1px solid #ddd","borderRadius":"12px","padding":"10px"}, children=[
                        html.Div("Blocked", style={"fontWeight":800,"fontFamily":"Arial"}),
                        DataTable(id="kanban_blk", data=[], columns=[{"name": c, "id": c} for c in [id_col, title_col, owner_col, priority_col, epic_col] if c in tickets_df.columns],
                                  row_selectable="multi", page_size=10, style_cell=DT_STYLE_CELL)
                    ]),
                    html.Div(style={"flex":1,"minWidth":"260px","border":"1px solid #ddd","borderRadius":"12px","padding":"10px"}, children=[
                        html.Div("Done", style={"fontWeight":800,"fontFamily":"Arial"}),
                        DataTable(id="kanban_done", data=[], columns=[{"name": c, "id": c} for c in [id_col, title_col, owner_col, priority_col, epic_col] if c in tickets_df.columns],
                                  row_selectable="multi", page_size=10, style_cell=DT_STYLE_CELL)
                    ]),
                ]),
            ]),

            dcc.Tab(label="Decisions", children=[
                html.Div(style={"display":"flex","gap":"8px","margin":"8px 0","flexWrap":"wrap"}, children=[
                    html.Button("Add Decision Row", id="btn_add_decision"),
                    html.Button("Save Decisions", id="btn_save_decisions"),
                    html.Button("Reload Decisions", id="btn_reload_decisions"),
                    html.Button("Export Decisions to Excel", id="btn_export_decisions"),
                    html.Div(id="decisions_dirty", style={"padding":"6px 10px","border":"1px solid #ddd","borderRadius":"10px", "fontFamily":"Arial"}),
                ]),
                html.Div(id="decisions_msg", style={"margin":"8px 0","fontFamily":"Arial"}),
                DataTable(
                    id="decisions_tbl",
                    data=[],
                    columns=[{"name": c, "id": c, "editable": True} for c in decisions_df.columns],
                    editable=True,
                    row_deletable=True,
                    page_size=12,
                    filter_action="native",
                    sort_action="native",
                    style_table={"overflowX":"auto"},
                    style_cell=DT_STYLE_CELL,
                ),
            ]),

            dcc.Tab(label="Roadmap", children=[
                DataTable(
                    data=roadmap_df.to_dict("records"),
                    columns=[{"name": c, "id": c} for c in roadmap_df.columns],
                    page_size=18,
                    filter_action="native",
                    sort_action="native",
                    style_table={"overflowX":"auto"},
                    style_cell=DT_STYLE_CELL,
                )
            ]),
        ]),
    ],
)

# ---------- Single writer to tickets_tbl.data ----------
@app.callback(
    Output("tickets_tbl", "data"),
    Output("tickets_kpis", "children"),
    Input("tickets_store", "data"),
)
def render_tickets(rows):
    df = pd.DataFrame(rows or []).fillna("")
    df = normalize_dates(df)
    return df.to_dict("records"), kpi_cards(df)

# Table edits update the store
@app.callback(
    Output("tickets_store", "data"),
    Input("tickets_tbl", "data_timestamp"),
    State("tickets_tbl", "data"),
    prevent_initial_call=True
)
def tickets_edited(_, rows):
    df = pd.DataFrame(rows or []).fillna("")
    df = normalize_dates(df)
    return df.to_dict("records")

# Ticket detail
@app.callback(
    Output("ticket_detail", "children"),
    Input("tickets_tbl", "active_cell"),
    State("tickets_tbl", "data"),
)
def show_ticket_detail(active_cell, rows):
    if not active_cell or not rows:
        return "Click any cell to view the full ticket row here."
    r = active_cell.get("row")
    if r is None or r >= len(rows):
        return "Click any cell to view the full ticket row here."
    row = rows[r]
    keys = [id_col, title_col, status_col, priority_col, owner_col, epic_col]
    ordered = {k: row.get(k, "") for k in keys if k in row}
    for k in row.keys():
        if k not in ordered:
            ordered[k] = row.get(k, "")
    return "\n".join([f"{k}: {v}" for k, v in ordered.items()])

# New Ticket -> store (and set Created/Updated if those columns exist)
@app.callback(
    Output("tickets_store", "data", allow_duplicate=True),
    Output("new_ticket_msg", "children"),
    Input("btn_add_ticket", "n_clicks"),
    State("new_title", "value"),
    State("new_status", "value"),
    State("new_priority", "value"),
    State("new_owner", "value"),
    State("new_epic", "value"),
    State("tickets_store", "data"),
    prevent_initial_call=True
)
def add_ticket(_, title, status, priority, owner, epic, rows):
    title = (title or "").strip()
    if not title:
        return no_update, "Title is required."

    rows = rows or []
    df = pd.DataFrame(rows).fillna("")
    df = normalize_dates(df)
    new_id = next_ticket_id(df, id_col)

    blank = {c: "" for c in df.columns} if len(df.columns) else {}
    for c in [id_col, title_col, status_col, priority_col, owner_col, epic_col]:
        blank.setdefault(c, "")

    # If user has Created/Updated columns, set them in YYYYMMDD
    for c in df.columns:
        if c.strip().lower() == "created":
            blank[c] = today_yyyymmdd()
        if c.strip().lower() == "updated":
            blank[c] = today_yyyymmdd()

    blank[id_col] = new_id
    blank[title_col] = title
    blank[status_col] = status or "To Do"
    blank[priority_col] = priority or "Medium"
    blank[owner_col] = (owner or "").strip()
    blank[epic_col] = (epic or "").strip()

    rows.append(blank)
    return normalize_dates(pd.DataFrame(rows)).to_dict("records"), f"Added {new_id}"

# Save / reload / export
@app.callback(
    Output("tickets_saved_hash", "data"),
    Output("tickets_msg", "children"),
    Input("btn_save_tickets", "n_clicks"),
    State("tickets_store", "data"),
    prevent_initial_call=True
)
def save_tickets(_, rows):
    df = normalize_dates(pd.DataFrame(rows or [])).fillna("")
    df.to_csv(TICKETS_CSV, index=False)
    return df_hash(df), f"Saved tickets to {TICKETS_CSV} at {now_str()}"

@app.callback(
    Output("tickets_store", "data", allow_duplicate=True),
    Output("tickets_saved_hash", "data", allow_duplicate=True),
    Output("tickets_msg", "children", allow_duplicate=True),
    Input("btn_reload_tickets", "n_clicks"),
    prevent_initial_call=True
)
def reload_tickets(_):
    df = load_tickets()
    df = ensure_columns(df, [id_col, title_col, status_col, priority_col, owner_col, epic_col]).fillna("")
    df[status_col] = df[status_col].replace("", "To Do")
    df = normalize_dates(df)
    return df.to_dict("records"), df_hash(df), f"Reloaded tickets at {now_str()}"

@app.callback(
    Output("tickets_msg", "children", allow_duplicate=True),
    Input("btn_export_tickets", "n_clicks"),
    State("tickets_store", "data"),
    prevent_initial_call=True
)
def export_tickets(_, rows):
    df = normalize_dates(pd.DataFrame(rows or [])).fillna("")
    safe_export_df_to_excel(EXPORT_TICKETS_SHEET, df)
    return f"Exported tickets → Excel sheet '{EXPORT_TICKETS_SHEET}' at {now_str()}"

# Dirty indicator
@app.callback(
    Output("tickets_dirty", "children"),
    Input("tickets_store", "data"),
    State("tickets_saved_hash", "data"),
)
def tickets_dirty(rows, saved_hash):
    df = normalize_dates(pd.DataFrame(rows or [])).fillna("")
    return "Unsaved changes" if df_hash(df) != (saved_hash or "") else "Saved"

# Kanban render from store
@app.callback(
    Output("kanban_todo", "data"),
    Output("kanban_ip", "data"),
    Output("kanban_blk", "data"),
    Output("kanban_done", "data"),
    Input("tickets_store", "data"),
)
def render_kanban(rows):
    df = normalize_dates(pd.DataFrame(rows or [])).fillna("")
    return (kanban_subset(df, "To Do"),
            kanban_subset(df, "In Progress"),
            kanban_subset(df, "Blocked"),
            kanban_subset(df, "Done"))

# Move selected on Kanban -> store
@app.callback(
    Output("tickets_store", "data", allow_duplicate=True),
    Output("kanban_msg", "children"),
    Input("btn_move_selected", "n_clicks"),
    State("move_target_status", "value"),
    State("kanban_todo", "selected_rows"),
    State("kanban_ip", "selected_rows"),
    State("kanban_blk", "selected_rows"),
    State("kanban_done", "selected_rows"),
    State("kanban_todo", "data"),
    State("kanban_ip", "data"),
    State("kanban_blk", "data"),
    State("kanban_done", "data"),
    State("tickets_store", "data"),
    prevent_initial_call=True
)
def move_selected(_, target, sel_todo, sel_ip, sel_blk, sel_done, data_todo, data_ip, data_blk, data_done, all_rows):
    target = target or "In Progress"
    selected_ids = []

    def pick(sel, data):
        if not sel or not data:
            return
        for i in sel:
            if 0 <= i < len(data):
                selected_ids.append(str(data[i].get(id_col, "")).strip())

    pick(sel_todo, data_todo)
    pick(sel_ip, data_ip)
    pick(sel_blk, data_blk)
    pick(sel_done, data_done)

    selected_ids = [x for x in selected_ids if x]
    if not selected_ids:
        return no_update, "No tickets selected."

    updated, moved = [], 0
    for r in (all_rows or []):
        rid = str(r.get(id_col, "")).strip()
        if rid in selected_ids:
            r[status_col] = target
            # bump Updated if column exists
            for c in r.keys():
                if c.strip().lower() == "updated":
                    r[c] = today_yyyymmdd()
            moved += 1
        updated.append(r)

    df = normalize_dates(pd.DataFrame(updated)).fillna("")
    return df.to_dict("records"), f"Moved {moved} tickets → {target}"

# Decisions render
@app.callback(
    Output("decisions_tbl", "data"),
    Input("decisions_store", "data"),
)
def render_decisions(rows):
    df = pd.DataFrame(rows or []).fillna("")
    return df.to_dict("records")

@app.callback(
    Output("decisions_store", "data"),
    Input("decisions_tbl", "data_timestamp"),
    State("decisions_tbl", "data"),
    prevent_initial_call=True
)
def decisions_edited(_, rows):
    return (rows or [])

@app.callback(
    Output("decisions_store", "data", allow_duplicate=True),
    Output("decisions_msg", "children", allow_duplicate=True),
    Input("btn_add_decision", "n_clicks"),
    State("decisions_store", "data"),
    prevent_initial_call=True
)
def add_decision(_, rows):
    rows = rows or []
    rows.append({"Date": now_str(), "Decision": "", "Rationale": "", "Owner": "", "Link": ""})
    return rows, "Added decision row."

@app.callback(
    Output("decisions_saved_hash", "data"),
    Output("decisions_msg", "children"),
    Input("btn_save_decisions", "n_clicks"),
    State("decisions_store", "data"),
    prevent_initial_call=True
)
def save_decisions(_, rows):
    df = pd.DataFrame(rows or []).fillna("")
    df.to_csv(DECISIONS_CSV, index=False)
    return df_hash(df), f"Saved decisions to {DECISIONS_CSV} at {now_str()}"

@app.callback(
    Output("decisions_store", "data", allow_duplicate=True),
    Output("decisions_saved_hash", "data", allow_duplicate=True),
    Output("decisions_msg", "children", allow_duplicate=True),
    Input("btn_reload_decisions", "n_clicks"),
    prevent_initial_call=True
)
def reload_decisions(_):
    df = load_decisions()
    df = ensure_columns(df, ["Date", "Decision", "Rationale", "Owner", "Link"]).fillna("")
    return df.to_dict("records"), df_hash(df), f"Reloaded decisions at {now_str()}"

@app.callback(
    Output("decisions_msg", "children", allow_duplicate=True),
    Input("btn_export_decisions", "n_clicks"),
    State("decisions_store", "data"),
    prevent_initial_call=True
)
def export_decisions(_, rows):
    df = pd.DataFrame(rows or []).fillna("")
    safe_export_df_to_excel(EXPORT_DECISIONS_SHEET, df)
    return f"Exported decisions → Excel sheet '{EXPORT_DECISIONS_SHEET}' at {now_str()}"

@app.callback(
    Output("decisions_dirty", "children"),
    Input("decisions_store", "data"),
    State("decisions_saved_hash", "data"),
)
def decisions_dirty(rows, saved_hash):
    df = pd.DataFrame(rows or []).fillna("")
    return "Unsaved changes" if df_hash(df) != (saved_hash or "") else "Saved"

# Autosave if dirty (tickets dates normalized before save)
@app.callback(
    Output("tickets_saved_hash", "data", allow_duplicate=True),
    Output("decisions_saved_hash", "data", allow_duplicate=True),
    Output("tickets_msg", "children", allow_duplicate=True),
    Output("decisions_msg", "children", allow_duplicate=True),
    Input("autosave", "n_intervals"),
    State("tickets_store", "data"),
    State("decisions_store", "data"),
    State("tickets_saved_hash", "data"),
    State("decisions_saved_hash", "data"),
)
def autosave(_, t_rows, d_rows, t_saved, d_saved):
    t_df = normalize_dates(pd.DataFrame(t_rows or [])).fillna("")
    d_df = pd.DataFrame(d_rows or []).fillna("")

    t_now = df_hash(t_df) if len(t_df.columns) else (t_saved or "")
    d_now = df_hash(d_df) if len(d_df.columns) else (d_saved or "")

    t_msg = no_update
    d_msg = no_update
    new_t = no_update
    new_d = no_update

    if len(t_df.columns) and t_now != (t_saved or ""):
        t_df.to_csv(TICKETS_CSV, index=False)
        new_t = t_now
        t_msg = f"Autosaved tickets at {now_str()}"

    if len(d_df.columns) and d_now != (d_saved or ""):
        d_df.to_csv(DECISIONS_CSV, index=False)
        new_d = d_now
        d_msg = f"Autosaved decisions at {now_str()}"

    return new_t, new_d, t_msg, d_msg

if __name__ == "__main__":
    app.run(debug=True, port=8050)
