# DFCS local smoke test set

Copy this whole repo to:

`C:\Users\victor_yt_lam\Documents\DCS\DCS Upgrade(Local)\LoadTest\DFCS`

JMeter expected at:

`C:\Shares\apache-jmeter-5.5\bin`

## What is posted with the username?

Login (`[02] .../LP/FGE002/Login`) POSTs:

| Field | Value |
|-------|--------|
| `userId` | `${UserName}` from CSV |
| `password` | **hardcoded** `1234abcD` (not from CSV) |
| `__RequestVerificationToken` | hardcoded token from recording (may be stale) |

After login, the script also posts CSV fields elsewhere:

| Step | Fields from CSV / fixed |
|------|-------------------------|
| `[03] SaveIniToSession` | `ctrlPt=${CtrlPtCd}`, plus fixed `machineID=W10581` |
| `[07] FCE006U06` | `target=${Target}` |
| `[08]/[10] FCE006U03` | `itemTarget=${Target}` (`TAKE` then `HAND`) |

## Local files

| File | Purpose |
|------|---------|
| `CSV/local_users.csv` | 2 users for smoke (`DFCS001`, `DFCS002`) |
| `local/DFCS_PrePro_local.jmx` | PrePro, 1 thread, 60s, local CSV path |
| `local/DFCS_UAT_local.jmx` | UAT, 1 thread, 60s, local CSV path |
| `local/DFCS_TRN_local.jmx` | TRN, 1 thread, 60s, local CSV path |
| `local/run_*_local.cmd` | Single-node non-GUI runners (creates output folder) |
| `local/open_PrePro_local_gui.cmd` | Opens PrePro local plan in JMeter GUI |

## How to run

1. Copy repo to the `DFCS` folder above (keep `CSV\` and `local\` intact).
2. Confirm JMeter exists:
   - `C:\Shares\apache-jmeter-5.5\bin\jmeter.bat`
   - `C:\Shares\apache-jmeter-5.5\bin\ApacheJMeter.jar`
3. Confirm you can reach the target host (PrePro/UAT `:8443`, TRN `:8444`).
4. Confirm `DFCS001` / `DFCS002` exist and password `1234abcD` is valid (or edit password in the JMX login sampler).
5. Double-click one of:
   - `local\run_PrePro_local.cmd`
   - `local\run_UAT_local.cmd`
   - `local\run_TRN_local.cmd`
6. Open the HTML report under `local\output_<Env>_<timestamp>\report\index.html`.

For GUI debugging: run `local\open_PrePro_local_gui.cmd`, then use **View Results Tree**.

### Troubleshooting: `Unable to access jarfile ...\binApacheJMeter.jar`

That missing `\` means JMeter was started with a bad working directory / path join.

- Re-pull/copy the updated `run_*_local.cmd` files (they call `"%JMETER_HOME%\bin\jmeter.bat"` by full path).
- Confirm `C:\Shares\apache-jmeter-5.5\bin\ApacheJMeter.jar` exists (folder name is `bin`, jar is inside it).
- Do **not** set `JMETER_HOME` to the `bin` folder; it must be `C:\Shares\apache-jmeter-5.5`.
- Run the `.cmd` by double-click or from its own folder; do not `cd` into `bin` and run a broken relative call.

## Local load settings

- Threads: `1`
- Ramp-up: `1` s
- Duration: `60` s
- CSV: `...\DFCS\CSV\local_users.csv`
- No distributed remotes (`-R` removed)

## Known blockers (not fixed here)

See `FIX_PLAN.md`. Most important for local login: hardcoded `__RequestVerificationToken` may cause login failure until tokens are extracted dynamically.
