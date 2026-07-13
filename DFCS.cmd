set timestamp=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set _system=DFCS
set _jmxFile=%cd%\%_system%.jmx
set _logFile=%cd%\%_system%_output_%timestamp%\%_system%_log_%timestamp%.jtl
set _output=%cd%\%_system%_output_%timestamp%

cd C:\Shares\apache-jmeter-5.5\bin

call jmeter.bat ^
-n -t "%_jmxFile%" ^
-l "%_logFile%" ^
-e ^
-o "%_output%" ^
-R "10.12.116.65:1099, 10.12.134.251:1099" ^

