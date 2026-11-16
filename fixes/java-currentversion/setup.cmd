@echo off
rem Run as administrator. See README section 1.1.
rem Applies the JavaSoft CurrentVersion fix now and installs a SYSTEM task that re-applies
rem it at boot and after any Windows Installer activity (e.g. automatic Java updates).
rem Plain .cmd on purpose: needs nothing beyond cmd.exe, reg and schtasks.
set "KEY=HKLM\SOFTWARE\JavaSoft\Java Runtime Environment"
set "TASK=GIGAmacro\Restore JavaSoft CurrentVersion"
set "LOG=%~dp0setup-cmd.log"

echo [1] Apply now > "%LOG%"
reg query "%KEY%\1.8" >nul 2>&1 && reg add "%KEY%" /v CurrentVersion /t REG_SZ /d 1.8 /f >> "%LOG%" 2>&1

echo [2] Register task >> "%LOG%"
schtasks /Create /TN "%TASK%" /XML "%~dp0RestoreJavaSoftCurrentVersion.xml" /F >> "%LOG%" 2>&1

echo [3] Test: clear value, run task, check it comes back >> "%LOG%"
reg delete "%KEY%" /v CurrentVersion /f >> "%LOG%" 2>&1
schtasks /Run /TN "%TASK%" >> "%LOG%" 2>&1
ping -n 11 127.0.0.1 >nul
reg query "%KEY%" /v CurrentVersion >> "%LOG%" 2>&1 && (echo TASK RESTORED VALUE >> "%LOG%") || (echo TASK DID NOT RESTORE; setting directly >> "%LOG%" & reg add "%KEY%" /v CurrentVersion /t REG_SZ /d 1.8 /f >> "%LOG%" 2>&1)

echo [4] Task details >> "%LOG%"
schtasks /Query /TN "%TASK%" /V /FO LIST >> "%LOG%" 2>&1
echo DONE >> "%LOG%"
type "%LOG%"
pause
