@echo off
setlocal EnableExtensions
REM Local smoke run for DFCS TRN
REM Run from local\ or localTest\ — paths are based on this script's folder.

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..") do set "DFCS_HOME=%%~fI"

set "JMETER_HOME=C:\Shares\apache-jmeter-5.5"
set "JMETER_BIN=%JMETER_HOME%\bin"
set "JMETER_BAT=%JMETER_BIN%\jmeter.bat"
set "JMETER_JAR=%JMETER_BIN%\ApacheJMeter.jar"
set "JMX=%SCRIPT_DIR%\DFCS_TRN_local.jmx"

if not exist "%JMETER_BAT%" (
  echo ERROR: JMeter not found: "%JMETER_BAT%"
  echo Install/extract JMeter 5.5 so that ApacheJMeter.jar is under bin\
  exit /b 1
)
if not exist "%JMETER_JAR%" (
  echo ERROR: Missing jar: "%JMETER_JAR%"
  exit /b 1
)
if not exist "%JMX%" (
  echo ERROR: Test plan not found: "%JMX%"
  exit /b 1
)

for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set "_d=%%c%%a%%b"
set "_t=%TIME: =0%"
set "_t=%_t:~0,2%%_t:~3,2%%_t:~6,2%"
set "timestamp=%_d%%_t%"
set "OUTDIR=%SCRIPT_DIR%\output_TRN_%timestamp%"
mkdir "%OUTDIR%" 2>nul

REM Call by full path so jar resolves to bin\ApacheJMeter.jar (not binApacheJMeter.jar)
call "%JMETER_BAT%" -n -t "%JMX%" -l "%OUTDIR%\results.jtl" -e -o "%OUTDIR%\report"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo JMeter exited with errorlevel=%RC%
  exit /b %RC%
)
echo Done. Report: "%OUTDIR%\report\index.html"
endlocal
