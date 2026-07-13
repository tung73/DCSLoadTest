@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "JMETER_HOME=C:\Shares\apache-jmeter-5.5"
set "JMETER_BAT=%JMETER_HOME%\bin\jmeter.bat"
set "JMX=%SCRIPT_DIR%DFCS_PrePro_local.jmx"

if not exist "%JMETER_BAT%" (
  echo ERROR: JMeter not found: "%JMETER_BAT%"
  exit /b 1
)
if not exist "%JMX%" (
  echo ERROR: Test plan not found: "%JMX%"
  exit /b 1
)

start "" "%JMETER_BAT%" -t "%JMX%"
endlocal
