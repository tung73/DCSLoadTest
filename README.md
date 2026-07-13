# DFCS Load Test

Apache JMeter load test for the **DFCS (DCS Front Counter System)** e-register **takeover / handover** flow against the Hong Kong Customs DCS application.

The suite simulates concurrent officers logging in, selecting a control point, performing e-register takeover/handover actions, then logging out.

## Project layout

```
.
├── DFCS_PrePro.jmx       # PrePro / UAT test plan (context /DCS, port 8443)
├── DFCS_TRN.jmx          # TRN test plan (context /DCS_TRN, port 8444)
├── DFCS_PrePro.cmd       # Windows runner for PrePro plan
├── DFCS_TRN.cmd          # Windows runner for TRN plan
├── CSV/
│   ├── pre_pro_10.12.116.65.csv   # Users for load generator 10.12.116.65
│   ├── pre_pro_10.12.134.251.csv  # Users for load generator 10.12.134.251
│   └── dfcs.prd.csv               # Sample / alternate user data
├── FIX_PLAN.md           # Known issues / fix plan (not applied yet)
└── README.md
```

## Environments

| Env | Test plan | Base URL | Notes |
|-----|-----------|----------|--------|
| **PrePro** | `DFCS_PrePro.jmx` | `https://prd.as.dcs.customs.hksarg:8443/DCS` | Default enabled profile in PrePro plan |
| **UAT** | `DFCS_PrePro.jmx` | `https://uat.as.dcs.customs.hksarg:8443/DCS` | Same `/DCS` context; enable UAT vars, disable PREPRO |
| **TRN** | `DFCS_TRN.jmx` | `https://trn.as.dcs.customs.hksarg:8444/DCS_TRN` | Separate plan; paths and port already set |

### PrePro plan profiles (`DFCS_PrePro.jmx`)

| Profile | Status | Host | Port | Threads | Ramp-up | Duration |
|---------|--------|------|------|---------|---------|----------|
| **PREPRO** | Enabled | `prd.as.dcs.customs.hksarg` | 8443 | 20 | 100 s | 600 s |
| **UAT** | Disabled | `uat.as.dcs.customs.hksarg` | 8443 | 60 | 100 s | (not set in UAT block) |

### TRN plan (`DFCS_TRN.jmx`)

| Profile | Status | Host | Port | Context | Threads | Ramp-up | Duration |
|---------|--------|------|------|---------|---------|---------|----------|
| **TRN** | Enabled | `trn.as.dcs.customs.hksarg` | 8444 | `/DCS_TRN` | 20 | 100 s | 600 s |

CSV path pattern (both plans): `...\DFCS\CSV\pre_pro_${__machineIP}.csv`

## What the test does

Each virtual user (thread) runs this HTTP flow (PrePro/UAT use `/DCS`; TRN uses `/DCS_TRN`):

| Step | Request | Purpose |
|------|---------|---------|
| 01 | `GET {ctx}/` | Open app; extract session token |
| 02 | `POST .../LP/FGE002/Login` | Log in with CSV `UserName` |
| 03 | `POST .../LP/FGE002/SaveIniToSession` | Save init / control point (`CtrlPtCd`) |
| 04 | `POST .../LP/FCE006/FCE006S00` | Enter e-register (FCE006) |
| 05 | `POST .../LP/FCE006/CheckControlPtSelection` | Validate control point selection |
| 06 | `GET  .../LP/FCE006/FCE006S01` | Open e-register screen |
| 07 | `POST .../LP/FCE006/FCE006U06` | Takeover / handover action (`Target`) |
| 08–11 | `FCE006U03` + `FCE006S01_Content` | Follow-up updates and content refresh |
| 12 | `.../LP/FGE002/FGE002E03` | Post-action GE step |
| 13 | `.../LP/FGE002/Logout` | Log out |

Session tokens are extracted from the start page via regex (`{ctx}/g/(.*)/LP`). Cookies are managed by JMeter’s HTTP Cookie Manager. Constant / random timers pace requests between steps.

## CSV input

Files under `CSV/` supply thread data (`ignoreFirstLine=true`, recycled, shared across threads):

| Column | Description |
|--------|-------------|
| `UserName` | Login user id (e.g. `DFCS001`) |
| `CtrlPtCd` | Control point code (e.g. `AAT`, `APP`, `A51`) |
| `Target` | Takeover/handover target flag (`O` or `S`) |

- `pre_pro_10.12.116.65.csv` — 60 users (mostly `Target=O`, some `S`)
- `pre_pro_10.12.134.251.csv` — 60 users (`Target=O`)
- `dfcs.prd.csv` — small sample (`UserId`, `STAMPCD`)

## Prerequisites

- [Apache JMeter 5.5](https://jmeter.apache.org/) (path used by the runners: `C:\Shares\apache-jmeter-5.5\bin`)
- Network access to the target host/port (`8443` for PrePro/UAT, `8444` for TRN)
- For distributed runs: JMeter servers listening on the remotes listed in the `.cmd` files
- CSV paths in the plans currently use a Windows share (`N:\ITMG\...`). Update `csvPath` (or copy CSVs and point to a local path) before running elsewhere.

## How to run

### Option A — Windows batch (distributed, non-GUI)

```bat
DFCS_PrePro.cmd
DFCS_TRN.cmd
```

Each runner:

1. Builds a timestamped output folder: `{plan}_output_<yyyyMMddHHmmss>\`
2. Runs JMeter non-GUI (`-n`) with the matching `.jmx`
3. Writes results to a `.jtl` log
4. Generates an HTML report (`-e -o`)
5. Distributes load to remotes: `10.12.116.65:1099` and `10.12.134.251:1099` (`-R`)

### Option B — JMeter GUI

**PrePro / UAT:** open `DFCS_PrePro.jmx`, enable **User Defined Variables -PREPRO** or **-UAT** (only one).

**TRN:** open `DFCS_TRN.jmx` (TRN variables already enabled).

### Option C — Command line (single node)

```bash
jmeter -n -t DFCS_PrePro.jmx -l DFCS_PrePro_results.jtl -e -o DFCS_PrePro_report
jmeter -n -t DFCS_TRN.jmx    -l DFCS_TRN_results.jtl    -e -o DFCS_TRN_report
```

## Notes

- Known functional issues (hardcoded CSRF tokens, etc.) are tracked in `FIX_PLAN.md` and are not fixed in this split.
- Credentials and CSRF-style tokens appear in the recorded requests; rotate or externalize them for anything beyond controlled load-test environments.
- Default PrePro/TRN load: **20 threads**, **100 s ramp-up**, **10 minutes** duration, looping until the scheduler stops.
