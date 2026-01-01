<#
.SYNOPSIS
    Automated setup for Intelligent Standby List Cleaner (ISLC).
    v2: Handles 7zip Self-Extracting Archive.
.DESCRIPTION
    1. Downloads ISLC v1.0.3.7 Setup (SFX) from Wagnardsoft.
    2. Extracts it to Documents\optimizations.
    3. Renames extracted folder to 'ISLC'.
    4. Configures it for optimal gaming performance (1024MB List Size, 0.5ms Timer).
    5. Sets the executable to run as Administrator.
    6. Creates a Scheduled Task to run ISLC minimized at user logon with highest privileges.
    7. Launches ISLC immediately.
#>

$ErrorActionPreference = "Stop"

# --- Configuration ---
$BaseDir = "$env:USERPROFILE\Documents\optimizations"
$InstallDir = "$BaseDir\ISLC"
$InstallerName = "ISLC_Setup.exe"
$InstallerPath = "$BaseDir\$InstallerName"
$DownloadUrl = "https://www.wagnardsoft.com/ISLC/ISLC%20v1.0.3.7.exe"
$TaskName = "Intelligent StandbyList Cleaner AutoStart"
$ProcessName = "Intelligent standby list cleaner ISLC"

# --- 1. Cleanup (Files & Task) ---
Write-Host "Cleaning up previous installations..." -ForegroundColor Cyan

# Stop Running Process
Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1 # Give it a moment to release file locks

# Remove existing Directory
if (Test-Path "$BaseDir\ISLC") { 
    Remove-Item "$BaseDir\ISLC" -Recurse -Force 
    Write-Host "Removed existing ISLC directory." -ForegroundColor Yellow
}

# Remove existing Scheduled Task
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing Scheduled Task." -ForegroundColor Yellow
}


$ExeName = "Intelligent standby list cleaner ISLC.exe"
$ExePath = "$InstallDir\$ExeName"
$ConfigFileName = "config.json"
$ConfigPath = "$InstallDir\$ConfigFileName"

# Optimized Configuration
# Calculate Total RAM / 2 for FreeMemoryValue
$ComputerInfo = Get-CimInstance Win32_ComputerSystem
$TotalRAM_MB = [math]::Round($ComputerInfo.TotalPhysicalMemory / 1MB)
$FreeMemValue = [math]::Round($TotalRAM_MB / 2)

Write-Host "Total RAM: $TotalRAM_MB MB. Setting FreeMemoryValue to: $FreeMemValue MB" -ForegroundColor Yellow

$ConfigJson = @"
{
  "StandbyListValue": "1024",
  "FreeMemoryValue": "$FreeMemValue",
  "StartMinimized": true,
  "AlwaysOnTop": false,
  "CustomTimer": true,
  "WantedResolution": 0.5,
  "PollingRateSTR": "1000",
  "ExclusionList": []
}
"@

# --- 1. Directory Setup & Cleanup ---
Write-Host "Checking directories..." -ForegroundColor Cyan
if (!(Test-Path -Path $BaseDir)) {
    New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null
}

# --- 2. Download Installer ---
Write-Host "Downloading ISLC Installer..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath
    Write-Host "Download complete: $InstallerPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to download ISLC. Check internet connection."
}

# --- 3. Extract SFX ---
Write-Host "Extracting ISLC..." -ForegroundColor Cyan
# 7zip SFX arguments: -y (yes to all), -o{Path} (output directory)
$Process = Start-Process -FilePath $InstallerPath -ArgumentList "-y", "-o`"$BaseDir`"" -PassThru -Wait
if ($Process.ExitCode -ne 0) {
    Write-Error "Extraction failed with exit code $($Process.ExitCode)"
}

# Cleanup Installer
if (Test-Path $InstallerPath) { Remove-Item $InstallerPath -Force }

# --- 4. Organize Folders (Dynamic Detection) ---
# Find the folder that contains the ISLC executable
$ExtractedFolder = Get-ChildItem -Path $BaseDir -Directory | Where-Object { 
    Test-Path "$($_.FullName)\$ExeName" 
} | Select-Object -First 1

if ($ExtractedFolder) {
    Write-Host "Found extracted folder: $($ExtractedFolder.Name)" -ForegroundColor Cyan
    Rename-Item -Path $ExtractedFolder.FullName -NewName "ISLC" -Force
    Write-Host "Renamed to: $InstallDir" -ForegroundColor Green
} else {
    Write-Error "Extraction check failed. Could not find any folder containing '$ExeName' in '$BaseDir'."
}

# --- 5. Apply Configuration ---
Write-Host "Applying optimized configuration..." -ForegroundColor Cyan
try {
    $ConfigJson | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
    Write-Host "Configuration saved to $ConfigPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to write config file."
}

# --- 6. Set Run as Administrator (Registry) ---
Write-Host "Setting 'Run as Administrator' flag..." -ForegroundColor Cyan
$RegPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
try {
    Set-ItemProperty -Path $RegPath -Name $ExePath -Value "~ RUNASADMIN" -ErrorAction Stop
    Write-Host "Registry flag set for RunAsAdmin." -ForegroundColor Green
}
catch {
    Write-Warning "Could not set Registry key. Run script as Admin."
}

# --- 7. Create Scheduled Task ---
Write-Host "Creating Scheduled Task..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction -Execute $ExePath -Argument "-minimized" -WorkingDirectory $InstallDir
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 0) -Priority 0
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Auto launch ISLC at log on with optimization settings"
    Write-Host "Scheduled Task created." -ForegroundColor Green
}
catch {
    Write-Error "Failed to create Scheduled Task."
}

# --- 8. Launch Immediately ---
Write-Host "Launching ISLC..." -ForegroundColor Cyan
if (Test-Path $ExePath) {
    Start-Process -FilePath $ExePath -ArgumentList "-minimized" -WorkingDirectory $InstallDir
    Write-Host "ISLC started minimized." -ForegroundColor Green
} else {
    Write-Error "Executable not found at $ExePath"
}

Write-Host "`nOptimization setup complete!" -ForegroundColor Magenta
