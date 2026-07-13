@echo off
set "DFCS_HOME=C:\Users\victor_yt_lam\Documents\DCS\DCS Upgrade(Local)\LoadTest\DFCS"
set "JMETER_BIN=C:\Shares\apache-jmeter-5.5\bin"
cd /d "%JMETER_BIN%"
start "" jmeter.bat -t "%DFCS_HOME%\local\DFCS_PrePro_local.jmx"
