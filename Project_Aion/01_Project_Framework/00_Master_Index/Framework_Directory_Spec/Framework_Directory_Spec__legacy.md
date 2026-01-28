# Framework Directory Spec (source of truth)

```text
# Master Directory Tree (generated UTC 2026-01-27T00:29:45+00:00)

docs/
└── scope_contract.md

notebooks/01_framework/
└── 01_Master_Index_Narration.ipynb
```
# Framework_Directory_Spec.md (v0.2)
**Project Aion — Directory Specification (Source of Truth)**  
**Last updated:** 2026-01-28

This document defines the canonical folder structure for Project Aion.  
Use it as the reference for all “add / edit / delete / move” requests.

---

## Naming conventions
- Top-level folders are numbered for ordering: `00_`, `01_`, `02_` …
- Use `_` underscores; avoid spaces.
- Prefer each major area to include:
  - `00_Overview/` (orientation + scope)
  - `README.md` (quick entry point)
- Subfolders typically follow: `00_Overview/`, `06_Integration/`, `07_Implementation/` (or similar).
- If we need to insert between numbers without renumbering, use `18A_` etc.
- Inline notes are allowed, but keep them short and clearly marked with comments.

---

## Top-level directory map

Project_Aion/
├── 00_Executive_Summary/
│   ├── 00_Overview/
│   └── README.md
│
├── 01_Project_Framework/
│   ├── 00_Master_Index/
│   │   └── 00_Master_Index.md
│   ├── 01_Project_Charter/
│   ├── 02_Roadmap_Gantt_Tickets/
│   ├── 03_Decisions_and_Change_Log/
│   ├── 04_Templates/
│   └── README.md
│
├── 02_Technology_Advantage/
├── 03_Information_Advantage/
├── 04_Trading_Advantage/
│
├── 05_Glass_Cockpit_GUI/
│   ├── 00_Overview/
│   ├── Panels/
│   ├── Design_System/
│   └── README.md
│
├── 06_Automation_Admin_AWACS/
│   ├── 00_Overview/
│   ├── Monitoring_and_Alerts/
│   ├── Controls_and_KillSwitches/
│   ├── Audit_and_Approvals/
│   └── README.md
│
├── 07_Databases/
│   ├── 00_Overview/
│   │   ├── Database_Strategy.md
│   │   ├── Data_Lifecycle_and_Ownership.md
│   │   └── Performance_and_Reliability_Goals.md
│   │
│   ├── 01_Operational_Datastores/
│   │   ├── Live_Market_Data.md
│   │   ├── State_and_Session_Store.md
│   │   └── Automation_Runtime_Data.md
│   │
│   ├── 02_Trading_and_Execution/
│   │   ├── Orders_and_Fills.md
│   │   ├── Positions_and_Exposure.md
│   │   └── PnL_and_Attribution.md
│   │
│   ├── 03_TimeSeries_and_Historical/
│   │   ├── Tick_and_Price_History.md
│   │   ├── Feature_Stores.md
│   │   └── Model_Inputs_and_Outputs.md
│   │
│   ├── 04_Analytics_and_Reporting/
│   │   ├── Aggregations_and_Cubes.md
│   │   ├── Dash_and_GUI_Feeds.md
│   │   └── Performance_Metrics.md
│   │
│   ├── 05_Governance_and_Audit/
│   │   ├── Audit_Logs.md
│   │   ├── Change_History.md
│   │   └── Regulatory_Readiness.md
│   │
│   ├── 06_Resilience_and_Backups/
│   │   ├── Replication_and_Failover.md
│   │   ├── Backup_and_Restore.md
│   │   └── Disaster_Recovery.md
│   │
│   ├── 07_Schemas_and_Migrations/
│   │   ├── Schema_Definitions/
│   │   ├── Migration_Scripts/
│   │   └── Versioning_Strategy.md
│   │
│   └── 08_Access_and_Security/
│       ├── Roles_and_Permissions.md
│       ├── Encryption_and_Secrets.md
│       └── Network_Isolation.md
│
├── 08_Trading_Engines/
│   ├── 00_Overview/
│   ├── Execution/
│   ├── Risk_Gates/
│   ├── Simulation_Adapters/
│   └── README.md
│
├── 09_Expert_Systems/
│   ├── 00_Overview/
│   ├── Rules_and_Vetoes/
│   ├── Explainability/
│   ├── Human_Labelled_Replay_Program.md
│   └── README.md
│
├── 10_Pulse_Race_Status_Bet_Triggers/
│   ├── 00_Overview/
│   ├── State_Model/
│   ├── Trigger_Definitions/
│   └── README.md
│
├── 11_GUI_Pulse_Input/
├── 12_Lead_and_Lag_Analysis/
│
├── 13_IT_Infrastructure/
│   ├── 00_Overview/
│   ├── Environments/
│   ├── CI_CD/
│   ├── Observability/
│   └── Security/
│
├── 14_ML_XGBOOST/
├── 15_MLflow/
│
├── 16_Modelling_Feature_Design_and_Engineering_Principles/
├── 17_Modelling_Statistic_Cohorts/
│
├── 18_Features_Profile/
├── 19_Features_Performance/
├── 19A_Features_Proprietary/   # positioned between Performance and Perception
│   ├── 00_Overview/
│   │   └── Purpose_and_Scope.md
│   ├── Replay_Labelled_Intelligence.md
│   └── README.md
│
├── 20_Features_Perception_Market/   # MRKRTG + crowd belief
├── 21_Features_Preferences/
├── 22_Features_Pace_Position_in_Run_PIR_RunStyle/
├── 23_Features_Projection/
├── 24_Features_Public_Live_Market/
│
├── 25_Ratings_Performance_POWRTG/
├── 26_Ratings_Performance_SPDRTG/
├── 27_Ratings_Perception_MRKRTG/
├── 28_Ratings_Performance_TRKSPD/
├── 29_Ratings_Performance_Grade_Benchmarks_Global_Standardization/
├── 30_Ratings_Performance_Time_Standards/
│
├── 31_Model_Simulation_Backtesting/
│   ├── 00_Overview/
│   ├── Replay_and_Event_Time/
│   ├── Execution_Simulation/
│   ├── Review_Packs/
│   └── README.md
│
├── 32_Trading_Strategies_Early_Mid_Late_Market/
├── 33_Trading_Strategies_Tote/
├── 34_Trading_Strategies_Exchange/
├── 35_Trading_Strategies_Fixed_Odds/
├── 36_Trading_Strategies_Dividend_Prediction/
├── 37_Trading_Strategies_cA_Continuous_Alpha/
│
├── 38_Business_Intelligence/
├── 39_Business_Intelligence_Reporting/
├── 40_Business_Intelligence_Reconciliation/
│
├── 41_Trading_Strategies_Staking_Kelly/
├── 42_Trading_Strategies_Staking_Isaacs/
│
├── 90_Assets_Icon_Library/
│   ├── 00_Overview/
│   ├── Icons/
│   ├── Components/
│   └── README.md
│
├── README.md
└── .gitignore
