@echo off
setlocal
REM Local smoke run for DFCS TRN
set "DFCS_HOME=C:\Users\victor_yt_lam\Documents\DCS\DCS Upgrade(Local)\LoadTest\DFCS"
set "JMETER_BIN=C:\Shares\apache-jmeter-5.5\bin"
set "JMX=%DFCS_HOME%\local\DFCS_TRN_local.jmx"

for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set _d=%%c%%a%%b
set _t=%TIME: =0%
set _t=%_t:~0,2%%_t:~3,2%%_t:~6,2%
set "timestamp=%_d%%_t%"
set "OUTDIR=%DFCS_HOME%\local\output_TRN_%timestamp%"
mkdir "%OUTDIR%" 2>nul

cd /d "%JMETER_BIN%"
call jmeter.bat -n -t "%JMX%" -l "%OUTDIR%\results.jtl" -e -o "%OUTDIR%\report"
echo.
echo Done. Report: "%OUTDIR%\report\index.html"
endlocal
