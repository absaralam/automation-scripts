@echo off
:: Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

echo ========================================================
echo                 GAMING OPTIMIZATION
echo ========================================================
echo.

echo Running ISLC Setup...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\ISLC.ps1"
echo.

echo Running MSI Mode Optimization...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\MSI_Mode.ps1"
echo.

echo Running Windows System Optimizations...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Windows_Opt.ps1"
echo.

echo Running Deep Network Optimizations...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Network_Opt.ps1"
echo.

echo Running Input Optimizations...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Input_Opt.ps1"
echo.

echo Running Gaming & Visual Optimizations...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Gaming_Opt.ps1"
echo.

echo Applying General Preferences...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\General_Prefs.ps1"
echo.

echo Removing Bloatware (Selected Apps)...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Bloat_Remove.ps1"
echo.

echo Optimizing Windows Services (CTT)...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Services_Opt.ps1"
echo.

echo Performing Final Cleanup...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts\Cleanup_Opt.ps1"

echo.
echo ========================================================
echo Script finished. Press any key to exit.
echo ========================================================
pause >nul
