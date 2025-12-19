@echo off
setlocal EnableDelayedExpansion
title Cloud Backup Manager (Universal)
cd /d "%~dp0"

:: --- CHECK FOR ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0 %*' -Verb RunAs"
    exit /b
)
set "RCLONE_URL=https://downloads.rclone.org/rclone-current-windows-amd64.zip"
set "INSTALL_DIR=%LOCALAPPDATA%\Programs\rclone"
set "RCLONE_EXE=%INSTALL_DIR%\rclone.exe"
set "RUNNER_SCRIPT=%INSTALL_DIR%\Visual_Runner.cmd"
set "SILENT_SCRIPT=%INSTALL_DIR%\Silent_Runner.cmd"
set "REMOTE_NAME=gdrive"
set "BACKUP_SOURCE=%USERPROFILE%\Documents\Archives"
set "BACKUP_DEST=%REMOTE_NAME%:Backups"
set "TASK_NAME=CloudBackup_Weekly"
set "LOG_FILE=%INSTALL_DIR%\backup.log"

:: --- MENU ---
:MENU
cls
echo ========================================================
echo           Cloud Backup Manager (Universal)
echo ========================================================
echo.
echo  [1] Run Backup Now
echo  [2] Install Weekly Schedule (Every Sunday @ 8PM)
echo  [3] Uninstall Schedule Only
echo  [4] FULL UNINSTALL (Remove Program + Schedule + Keys)
echo  [5] Exit
echo.
set /p "Choice=Select an option: "

if "%Choice%"=="1" goto :PRE_CHECK
if "%Choice%"=="2" goto :INSTALL_SCHEDULE
if "%Choice%"=="3" goto :UNINSTALL_SCHEDULE
if "%Choice%"=="4" goto :FULL_UNINSTALL
if "%Choice%"=="5" exit
goto :MENU

:: --- 1. DETECTION PRE-CHECK ---
:PRE_CHECK
:: Check Global Path
where rclone >nul 2>nul
if %errorLevel% equ 0 (
    echo [INFO] Rclone found in Global PATH.
    for /f "tokens=*" %%i in ('where rclone') do set "RCLONE_EXE=%%i"
    goto :CHECK_CONFIG
)

:: Check Local Install
if exist "%RCLONE_EXE%" goto :CHECK_CONFIG

:: --- 2. INSTALLATION ---
echo [INFO] Rclone not found. Starting Universal Installer...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [DOWNLOADING] %RCLONE_URL%
powershell -Command "Invoke-WebRequest -Uri '%RCLONE_URL%' -OutFile 'rclone.zip'"

echo [EXTRACTING]...
powershell -Command "Expand-Archive -Path 'rclone.zip' -DestinationPath '%INSTALL_DIR%' -Force"

echo [CLEANING UP]...
for /d %%I in ("%INSTALL_DIR%\rclone-*-windows-amd64") do (
    move /y "%%I\rclone.exe" "%INSTALL_DIR%\" >nul
    rmdir /s /q "%%I"
)
if exist "rclone.zip" del "rclone.zip"

echo [SETUP] Adding to User PATH...
powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';%INSTALL_DIR%', 'User')"

:: --- 3. ZERO-TOUCH IMPORT ---
set "RCLONE_CONF_DIR=%APPDATA%\rclone"
set "RCLONE_CONF_FILE=%RCLONE_CONF_DIR%\rclone.conf"
set "LOCAL_CONF=%~dp0rclone.conf"

if exist "%LOCAL_CONF%" (
    if not exist "%RCLONE_CONF_FILE%" (
        echo [SETUP] Found local 'rclone.conf'. Importing...
        if not exist "%RCLONE_CONF_DIR%" mkdir "%RCLONE_CONF_DIR%"
        copy /y "%LOCAL_CONF%" "%RCLONE_CONF_FILE%" >nul
        echo [SUCCESS] Configuration imported/restored!
    )
)

:CHECK_CONFIG
:: --- GENERATE PERMANENT RUNNERS ---
:: We create these small scripts regardless, so the scheduler relies on fixed paths
echo [SETUP] Generating Persistent Runners in %%INSTALL_DIR%%...
(
echo @echo off
echo echo [BACKUP] Syncing Archives to Google Drive...
echo "%RCLONE_EXE%" copy "%BACKUP_SOURCE%" "%BACKUP_DEST%" --progress --create-empty-src-dirs 
echo if %%errorLevel%% equ 0 echo [SUCCESS] Done. ^& timeout 5
echo if %%errorLevel%% neq 0 echo [ERROR] Failed. ^& pause
) > "%RUNNER_SCRIPT%"

(
echo @echo off
echo "%RCLONE_EXE%" copy "%BACKUP_SOURCE%" "%BACKUP_DEST%" --create-empty-src-dirs --config="%RCLONE_CONF_FILE%" --log-level INFO ^> "%LOG_FILE%" 2^>^&1
) > "%SILENT_SCRIPT%"

:: --- 4. CONFIG CHECK ---
"%RCLONE_EXE%" listremotes | findstr /i "%REMOTE_NAME%" >nul
if %errorLevel% equ 0 goto :RUN_BACKUP

:: --- 5. INTERACTIVE SETUP ---
echo.
echo [WARNING] Remote '%REMOTE_NAME%' not configured!
echo [INFO] Launching setup wizard...
echo.
"%RCLONE_EXE%" config
"%RCLONE_EXE%" listremotes | findstr /i "%REMOTE_NAME%" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Setup cancelled or failed.
    pause
    goto :MENU
)

:RUN_BACKUP
call "%RUNNER_SCRIPT%"
goto :MENU

:: --- SCHEDULER FUNCTIONS ---
:INSTALL_SCHEDULE
echo.
echo [SCHEDULER] Installing Weekly Task (Hidden Mode - SYSTEM Context)...
:: Use PowerShell to register the task with the -Hidden attribute (just like Cat SIS)
:: 1. Cleanup old task first (Idempotency)
set "PS_CMD=Unregister-ScheduledTask -TaskName '%TASK_NAME%' -Confirm:$false -ErrorAction SilentlyContinue;"

:: 2. Register new task
set "PS_CMD=!PS_CMD! $Action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c \""%SILENT_SCRIPT%\""';"
set "PS_CMD=!PS_CMD! $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8pm;"
set "PS_CMD=!PS_CMD! $Principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest -LogonType ServiceAccount;"
set "PS_CMD=!PS_CMD! $Settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable;"
set "PS_CMD=!PS_CMD! Register-ScheduledTask -TaskName '%TASK_NAME%' -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force"

powershell -Command "%PS_CMD%"
if %errorLevel% equ 0 echo [SUCCESS] Task Installed! Runs silently every Sunday at 8:00 PM (As SYSTEM).
pause
goto :MENU

:UNINSTALL_SCHEDULE
echo.
echo [SCHEDULER] Removing Weekly Task...
schtasks /delete /tn "%TASK_NAME%" /f
if %errorLevel% equ 0 echo [SUCCESS] Task Removed.
pause
goto :MENU

:: --- CLEANUP FUNCTION ---
:FULL_UNINSTALL
cls
echo ========================================================
echo                   FULL UNINSTALL
echo ========================================================
echo.
echo  [WARNING] This will DELETE:
echo   1. The Rclone Program + Runner Scripts (%INSTALL_DIR%)
echo   2. The Weekly Schedule Task (%TASK_NAME%)
echo   3. Your Configuration Keys (%APPDATA%\rclone)
echo.
echo  Are you sure you want to proceed?
echo.
set /p "Confirm=Type 'YES' to confirm: "
if /i not "%Confirm%"=="YES" goto :MENU

echo.
echo [1/3] Removing Schedule...
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>nul
echo Done.

echo [2/3] Removing Rclone Program...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
echo Done.

echo [3/3] Removing Config...
if exist "%APPDATA%\rclone" rmdir /s /q "%APPDATA%\rclone"
echo Done.

echo.
echo [SUCCESS] Everything has been scrubbed clean.
pause
exit
