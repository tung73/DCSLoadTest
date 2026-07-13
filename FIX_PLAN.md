# DFCS load-test bug review and fix plan

Review of `DFCS.cmd`, `DFCS.jmx`, and `CSV/`. Issues are ordered by severity (P0 = will break or corrupt a run; P3 = hygiene).

## Findings summary

| ID | Severity | Area | Issue |
|----|----------|------|--------|
| B1 | P0 | `DFCS.jmx` | Hardcoded `__RequestVerificationToken` values from recording |
| B2 | P0 | `DFCS.jmx` | UAT profile missing `duration` while scheduler is on |
| B3 | P0 | `DFCS.cmd` | Output folder never created before writing `.jtl` |
| B4 | P1 | `DFCS.cmd` | Trailing `^` on last line; fragile timestamp |
| B5 | P1 | `DFCS.jmx` | Cookies not cleared between login/logout iterations |
| B6 | P1 | `DFCS.jmx` | Hardcoded `machineID=W10581` for every thread |
| B7 | P1 | `DFCS.jmx` | PREPRO profile targets `prd.as.dcs...` host |
| B8 | P2 | `DFCS.jmx` | Referer headers embed stale session + fixed `ctrl_pt_cd=APP` |
| B9 | P2 | `DFCS.jmx` | `port` / `scheme` UDVs unused or inconsistent |
| B10 | P2 | `CSV/` | `dfcs.prd.csv` columns don’t match CSV Data Set |
| B11 | P2 | `DFCS.jmx` | Empty CSV `delimiter`; no assertions / extract failure handling |
| B12 | P3 | `DFCS.jmx` | Disabled recorder leftovers; plaintext password in plan |

---

## P0 — Fix first

### B1. Hardcoded anti-forgery tokens

**Where:** Login `[02]` and FCE006 entry `[04]` POST bodies use fixed `__RequestVerificationToken` strings captured during recording.

**Why it fails:** ASP.NET tokens are session/page-scoped. A load run after a new app session will reject login / navigation with 400 or redirect-to-login, so most samples look “successful” as HTML error pages unless asserted.

**Fix:**
1. After `[01]-Start` (and after any page that issues a new form), add a Regex/CSS extractor for `__RequestVerificationToken`.
2. Replace hardcoded values with `${csrfToken}` (or per-page vars).
3. Re-extract after login if the app rotates the token before `[04]`.

**Verify:** Single-thread GUI run; login and `[04]` return 200 with expected content (not login page).

### B2. UAT profile has no `duration`

**Where:** Thread Group has `scheduler=true` and `duration=${duration}`. PREPRO defines `duration=600`; UAT does not.

**Why it fails:** Enabling UAT leaves `${duration}` unresolved → empty scheduler duration → threads stop immediately or behave unpredictably.

**Fix:** Add `duration` to the UAT variable set (e.g. `600` or the intended UAT value). Optionally set a Test Plan–level default so a missing profile cannot blank it out.

### B3. `DFCS.cmd` writes `.jtl` into a non-existent directory

**Where:**
```bat
set _logFile=%cd%\%_system%_output_%timestamp%\%_system%_log_%timestamp%.jtl
set _output=%cd%\%_system%_output_%timestamp%
```
No `mkdir` before `jmeter -l "%_logFile%"`.

**Why it fails:** JMeter does not create parent dirs for `-l`. The run can fail before the HTML report (`-o`) is generated.

**Fix:**
```bat
mkdir "%_output%" 2>nul
```
before calling `jmeter.bat`. Prefer writing the `.jtl` into that folder after it exists.

---

## P1 — High impact

### B4. Batch runner line-continuation and timestamp bugs

**Where:** Last `-R ... ^` has a trailing caret; `%TIME:~0,2%` can include a leading space (hours 0–9).

**Why it fails:** Trailing `^` continues the command onto the next line (often breaking the invocation). A space in the timestamp produces an invalid/awkward folder name and can split arguments.

**Fix:**
1. Remove the final `^`.
2. Normalize time: `set timestamp=%timestamp: =0%` (or use `wmic`/`powershell` for a zero-padded stamp).
3. Optionally drop the space after the comma in `-R "host1:1099,host2:1099"`.

### B5. Cookie jar not cleared per iteration

**Where:** HTTP Cookie Manager has `clearEachIteration=false` while the thread loops login → work → logout forever for `duration`.

**Why it fails:** Stale session cookies after logout/login can confuse the server or skip a clean session, especially if logout fails.

**Fix:** Set `clearEachIteration=true`, or clear cookies explicitly after `[13] Logout`. Keep `SessionToken` re-extracted each iteration (already from `[01]`).

### B6. Hardcoded `machineID=W10581`

**Where:** `[03] SaveIniToSession` always posts `machineID=W10581`.

**Why it fails:** All virtual users appear as one workstation. Backend uniqueness / concurrency rules may reject or serialize sessions incorrectly under load.

**Fix:** Drive `machineID` from CSV (new column) or `${__threadNum}` / `${__machineName}` with a documented format the app accepts. Confirm with the app team what IDs are valid in PREPRO/UAT.

### B7. PREPRO variables point at production host

**Where:** `User Defined Variables -PREPRO` sets `host=prd.as.dcs.customs.hksarg`.

**Why it fails:** Easy to run a “PREPRO” load test against production. Dangerous and may explain unexpected prod traffic.

**Fix:** Confirm the correct PREPRO hostname with the environment owners; rename profiles to match real hosts (`-PRD` vs `-PREPRO`); add a comment or fail-fast check so PRD requires an explicit override.

---

## P2 — Correctness / maintainability

### B8. Stale Referer session + fixed control point

**Where:** Almost every Referer still contains recorded session `ea5f890d...` and many use `ctrl_pt_cd=APP` even when CSV `CtrlPtCd` differs.

**Why it matters:** Paths use `${SessionToken}` correctly; Referer usually is not auth-critical. If the app validates Referer or correlates control point, requests can fail intermittently.

**Fix:** Replace with `${scheme}://${host}:8443/DCS/g/${SessionToken}/...` and `${CtrlPtCd}` where the URL includes a control point. Or drop Referer if the server does not require it.

### B9. Unused / inconsistent port and scheme

**Where:** UDVs define `port` and `scheme`, but HTTP Request Defaults use empty port + hardcoded `https`, while each sampler hardcodes port `8443`.

**Fix:** Set defaults to `${host}`, `${port}`, `${scheme}` and clear per-sampler domain/port/protocol overrides so one profile switch changes everything.

### B10. `dfcs.prd.csv` schema mismatch

**Where:** File columns are `UserId,STAMPCD`; CSV Data Set expects `UserName,CtrlPtCd,Target`.

**Fix:** Align columns or document that the file is unused. Prefer deleting or renaming if obsolete so it is not picked by mistake.

### B11. CSV delimiter empty; no pass/fail checks

**Where:** `CSVDataSet.delimiter` is empty (JMeter usually falls back to `,`, but it is implicit). No Response Assertions; Regex Extractor has empty default for `SessionToken`.

**Fix:**
1. Set delimiter to `,` explicitly.
2. Add a “SessionToken not empty” assertion after `[01]`.
3. Add status/body assertions on Login and TAKE/HAND steps so HTML error pages count as failures.
4. Consider `on_sample_error=startnextloop` instead of `continue` after login failure.

---

## P3 — Hygiene

### B12. Recorder clutter and secrets in repo

- Many disabled samplers still hardcode the recorded session path.
- Password `1234abcD` is committed in the JMX.

**Fix:** Remove disabled recorder noise (or move to a `recording/` archive). Externalize password via CSV, JMeter property (`-Jpassword=`), or a local untracked user.properties. Rotate the published password if it is still valid anywhere.

---

## Suggested implementation order

```text
1. DFCS.cmd     → B3, B4          (runner must work before analyzing results)
2. DFCS.jmx     → B1, B2, B5      (tokens, UAT duration, cookies)
3. DFCS.jmx     → B6, B8, B9, B11 (identity, headers, defaults, assertions)
4. Config/CSV   → B7, B10, B12    (env naming, CSV cleanup, secrets)
5. Dry-run      → 1 thread GUI on UAT, then short PREPRO soak, then full -R run
```

## Out of scope / needs product confirmation

- Whether TAKE then HAND in one iteration is the intended business flow (script does both every loop).
- Whether disabled `CheckHandoverDCO` must be re-enabled for a valid handover.
- Valid `machineID` / user / control-point matrix for each environment.
- Whether Referer validation is enforced by DCS.

## Done when

- [ ] `DFCS.cmd` creates output dir and runs without line-continuation errors
- [ ] CSRF tokens extracted dynamically; login succeeds for multiple iterations
- [ ] UAT and PREPRO both define `duration` (and hosts are confirmed)
- [ ] Cookies cleared (or proven safe) across iterations
- [ ] Assertions fail the sample on login/token/takeover errors
- [ ] README updated with any path/property changes
