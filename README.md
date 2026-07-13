# DFCS Load Test

Apache JMeter load test for the **DFCS (DCS Front Counter System)** e-register **takeover / handover** flow against the Hong Kong Customs DCS application.

The suite simulates concurrent officers logging in, selecting a control point, performing e-register takeover/handover actions, then logging out.

## Project layout

```
.
├── DFCS.jmx              # JMeter 5.5 test plan
├── DFCS.cmd              # Windows runner (non-GUI, distributed)
├── CSV/
│   ├── pre_pro_10.12.116.65.csv   # Users for load generator 10.12.116.65
│   ├── pre_pro_10.12.134.251.csv  # Users for load generator 10.12.134.251
│   └── dfcs.prd.csv               # Sample / alternate user data
└── README.md
```

## What the test does

Test plan name: **DFCS e-register takeover handover**

Each virtual user (thread) runs this HTTP flow against `/DCS/` on port `8443` (HTTPS):

| Step | Request | Purpose |
|------|---------|---------|
| 01 | `GET /DCS/` | Open app; extract session token |
| 02 | `POST .../LP/FGE002/Login` | Log in with CSV `UserName` |
| 03 | `POST .../LP/FGE002/SaveIniToSession` | Save init / control point (`CtrlPtCd`) |
| 04 | `POST .../LP/FCE006/FCE006S00` | Enter e-register (FCE006) |
| 05 | `POST .../LP/FCE006/CheckControlPtSelection` | Validate control point selection |
| 06 | `GET  .../LP/FCE006/FCE006S01` | Open e-register screen |
| 07 | `POST .../LP/FCE006/FCE006U06` | Takeover / handover action (`Target`) |
| 08–11 | `FCE006U03` + `FCE006S01_Content` | Follow-up updates and content refresh |
| 12 | `POST .../LP/FGE002/FGE002E03` | Post-action GE step |
| 13 | `GET  .../LP/FGE002/Logout` | Log out |

Session tokens are extracted from the start page via regex (`DCS/g/(.*)/LP`). Cookies are managed by JMeter’s HTTP Cookie Manager. Constant / random timers pace requests between steps.

## Environments

Two variable sets are defined in the test plan (enable one at a time):

| Profile | Status in plan | Host | Threads | Ramp-up | Duration |
|---------|----------------|------|---------|---------|----------|
| **PREPRO** | Enabled | `prd.as.dcs.customs.hksarg` | 20 | 100 s | 600 s |
| **UAT** | Disabled | `uat.as.dcs.customs.hksarg` | 60 | 100 s | (not set in UAT block) |

Shared settings:

- Protocol: `https`
- Port: `8443`
- CSV path pattern: `...\DFCS\CSV\pre_pro_${__machineIP}.csv`  
  (each load generator picks its own CSV by machine IP)

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

- [Apache JMeter 5.5](https://jmeter.apache.org/) (path used by the runner: `C:\Shares\apache-jmeter-5.5\bin`)
- Network access to the target DCS host on port 8443
- For distributed runs: JMeter servers listening on the remotes listed in `DFCS.cmd`
- CSV paths in the plan currently use a Windows share (`N:\ITMG\...`). Update `csvPath` (or copy CSVs and point to a local path) before running elsewhere.

## How to run

### Option A — Windows batch (distributed, non-GUI)

Edit `DFCS.cmd` if your JMeter install path or remote engines differ, then run:

```bat
DFCS.cmd
```

What it does:

1. Builds a timestamped output folder: `DFCS_output_<yyyyMMddHHmmss>\`
2. Runs JMeter non-GUI (`-n`) with `DFCS.jmx`
3. Writes results to a `.jtl` log
4. Generates an HTML report (`-e -o`)
5. Distributes load to remotes: `10.12.116.65:1099` and `10.12.134.251:1099` (`-R`)

### Option B — JMeter GUI

1. Open `DFCS.jmx` in JMeter 5.5.
2. Enable **User Defined Variables -PREPRO** or **-UAT** (only one).
3. Adjust `csvPath` / thread settings if needed.
4. Run the Thread Group and inspect **View Results Tree** / **Aggregate Report**.

### Option C — Command line (single node)

```bash
jmeter -n -t DFCS.jmx \
  -l DFCS_results.jtl \
  -e -o DFCS_report
```

## Notes

- The test plan was recorded against DCS (`HTTP(S) Test Script Recorder` is still present); some samplers remain disabled leftovers from recording.
- Credentials and CSRF-style tokens appear in the recorded requests; rotate or externalize them for anything beyond controlled load-test environments.
- Default PREPRO load: **20 threads**, **100 s ramp-up**, **10 minutes** duration, looping until the scheduler stops.
