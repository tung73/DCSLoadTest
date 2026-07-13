@echo off
setlocal EnableExtensions
REM Local smoke run for DFCS TRN
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "JMETER_HOME=C:\Shares\apache-jmeter-5.5"
set "JMETER_BAT=%JMETER_HOME%\bin\jmeter.bat"
set "JMETER_JAR=%JMETER_HOME%\bin\ApacheJMeter.jar"
set "JMX=%SCRIPT_DIR%\DFCS_TRN_local.jmx"
set "CSV_EXPECT=%SCRIPT_DIR%\..\CSV\local_users.csv"

if not exist "%JMETER_BAT%" (echo ERROR: missing "%JMETER_BAT%" & exit /b 1)
if not exist "%JMETER_JAR%" (echo ERROR: missing "%JMETER_JAR%" & exit /b 1)
if not exist "%JMX%" (echo ERROR: missing "%JMX%" & exit /b 1)
if not exist "%CSV_EXPECT%" (
  echo WARNING: CSV not found at "%CSV_EXPECT%"
  echo Check csvPath inside the JMX User Defined Variables.
)

for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set "_d=%%c%%a%%b"
set "_t=%TIME: =0%"
set "_t=%_t:~0,2%%_t:~3,2%%_t:~6,2%"
set "OUTDIR=%SCRIPT_DIR%\output_TRN_%_d%%_t%"
set "JTL=%OUTDIR%\results.jtl"
set "REPORT=%OUTDIR%\report"
mkdir "%OUTDIR%" 2>nul

echo Running test (no HTML report yet^)...
echo   JMX=%JMX%
echo   JTL=%JTL%
call "%JMETER_BAT%" -n -t "%JMX%" -l "%JTL%"
set "RC=%ERRORLEVEL%"
echo.

if not exist "%JTL%" (
  echo ERROR: results file was not created: "%JTL%"
  exit /b 1
)

set "LINES=0"
for /f %%C in ('find /c /v "" ^< "%JTL%"') do set "LINES=%%C"
echo results.jtl line count=%LINES% (1 = header only / no samples^)
if %LINES% LEQ 1 (
  echo.
  echo ERROR: No samples were recorded. HTML report would crash ^(JsonExporter NPE^).
  echo Open the JMeter log above for CSV/path/host errors, then check:
  echo   - csvPath in JMX points to an existing local_users.csv
  echo   - host/port reachable
  echo   - "%JTL%"
  exit /b 2
)

echo Generating HTML report into fresh folder...
if exist "%REPORT%" rmdir /s /q "%REPORT%"
call "%JMETER_BAT%" -g "%JTL%" -o "%REPORT%"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo Report generation failed, errorlevel=%RC%
  echo Samples are still in "%JTL%"
  exit /b %RC%
)
echo Done. Report: "%REPORT%\index.html"
endlocal
