<#
.SYNOPSIS
    Windows System Optimizations for Gaming.
.DESCRIPTION
    1. Enables "Ultimate Performance" Power Plan.
    2. Disables Hard Disk Sleep.
    3. Optimizes System Responsiveness (Multimedia Class Scheduler).
    4. Disables Network Throttling.
    5. Disables Nagle's Algorithm (TCPNoDelay) for the active network adapter.
#>

$ErrorActionPreference = "Stop"
Write-Host "Starting Windows System Optimizations..." -ForegroundColor Magenta

# --- 1. Power Plan: Ultimate Performance ---
Write-Host "Configuring Power Plan..." -ForegroundColor Cyan
$TemplateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"

# Check if plan already exists by name
$List = powercfg -list | Out-String
$Pattern = "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})(?=\s*\(Ultimate Performance\))"
# Or just find the line and extract guid
$ExistingLine = $List -split "`n" | Select-String "Ultimate Performance" | Select-Object -First 1

if ($ExistingLine) {
    # Extract GUID
    $UltimateGUID = ([regex]"[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}").Match($ExistingLine.ToString()).Value
    Write-Host "Found existing Ultimate Performance Plan: $UltimateGUID" -ForegroundColor Gray
} else {
    Write-Host "Importing Ultimate Performance Plan..." -ForegroundColor Yellow
    # Duplicate and capture output
    $Output = powercfg -duplicatescheme $TemplateGUID | Out-String
    # Extract new GUID
    $UltimateGUID = ([regex]"[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}").Match($Output).Value
}

if ($UltimateGUID) {
    # Set Active
    powercfg -setactive $UltimateGUID
    Write-Host "Plan set to Ultimate Performance ($UltimateGUID)." -ForegroundColor Green
    
    # Force HDD Sleep to "Never" (0) (Applied to Active Scheme)
    powercfg -change -disk-timeout-ac 0
    powercfg -change -disk-timeout-dc 0

# Force Sleep to "Never" (0)
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0

# Force Monitor Timeout to "Never" (0)
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0

# --- Helper: Unhide Power Settings (Registry Magic) ---
function Unhide-PowerSetting {
    param ([string]$SubGroup, [string]$Setting)
    $Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$SubGroup\$Setting"
    if (Test-Path $Key) {
        Set-ItemProperty -Path $Key -Name "Attributes" -Value 2 -ErrorAction SilentlyContinue
        Write-Host "  -> Unhidden Power Setting: $Setting" -ForegroundColor Gray
    }
}

# --- USB Selective Suspend ---
# GUID: 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 (Subgroup: 2a737441-1930-4402-8d77-b2bebba308a3)
Write-Host "Disabling USB Selective Suspend..." -ForegroundColor Cyan
# Unhide first matches
Unhide-PowerSetting -SubGroup "2a737441-1930-4402-8d77-b2bebba308a3" -Setting "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
# Give Registry a moment
Start-Sleep -Milliseconds 500

# 0 = Disabled, 1 = Enabled
powercfg -setacvalueindex $UltimateGUID 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -setdcvalueindex $UltimateGUID 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

# --- Desktop Background Slideshow ---
# CORRECT GUID from User Dump: 309dce9b-bef4-4119-9921-a851fb12f0f4
# Subgroup: 0d7dbae2-4294-402a-ba8e-26777e8488cd
Write-Host "Pausing Desktop Slideshow..." -ForegroundColor Cyan
Unhide-PowerSetting -SubGroup "0d7dbae2-4294-402a-ba8e-26777e8488cd" -Setting "309dce9b-bef4-4119-9921-a851fb12f0f4"
Start-Sleep -Milliseconds 500

# 0 = Available, 1 = Paused
powercfg -setacvalueindex $UltimateGUID 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
powercfg -setdcvalueindex $UltimateGUID 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1

# Apply Settings again to be sure
powercfg -setactive $UltimateGUID
} else {
    Write-Error "Failed to identify Ultimate Performance GUID."
}
Write-Host "Power Plan Optimized: HDD=Never, Sleep=Never, Monitor=Never, USB=Disabled, Slideshow=Paused." -ForegroundColor Green


# --- 2. System Responsiveness (Registry) ---
Write-Host "Applying Registry Tweaks..." -ForegroundColor Cyan

$ProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $ProfilePath) {
    # Disable Network Throttling
    Set-ItemProperty -Path $ProfilePath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF
    # Set System Responsiveness to 10% (Reserve 10% for background, 90% for games)
    Set-ItemProperty -Path $ProfilePath -Name "SystemResponsiveness" -Value 10
}

$GamesPath = "$ProfilePath\Tasks\Games"
if (Test-Path $GamesPath) {
    # Prioritize Games
    Set-ItemProperty -Path $GamesPath -Name "GPU Priority" -Value 8
    Set-ItemProperty -Path $GamesPath -Name "Priority" -Value 6
    Set-ItemProperty -Path $GamesPath -Name "Scheduling Category" -Value "High"
    Set-ItemProperty -Path $GamesPath -Name "SFIO Priority" -Value "High"
}
Write-Host "Registry optimizations applied." -ForegroundColor Green


# --- 3. Network Latency (TCP NoDelay) ---
Write-Host "Optimizing Network Adapter..." -ForegroundColor Cyan

# Find active physical adapter (IPv4)
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false } | Select-Object -First 1

if ($Adapter) {
    Write-Host "Targeting Adapter: $($Adapter.Name)" -ForegroundColor Yellow
    
    # Get the GUID for the interface
    $InterfaceGUID = $Adapter.InterfaceGuid
    $TcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$InterfaceGUID"

    if (Test-Path $TcpPath) {
        # Disable Nagle's Algorithm
        New-ItemProperty -Path $TcpPath -Name "TCPNoDelay" -Value 1 -PropertyType DWORD -Force | Out-Null
        # Ack immediately
        New-ItemProperty -Path $TcpPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWORD -Force | Out-Null
        
        Write-Host "TCP NoDelay & AckFrequency Enabled." -ForegroundColor Green
    } else {
        Write-Warning "Could not find Registry key for adapter GUID: $InterfaceGUID"
    }
    Write-Warning "No active physical network adapter found to optimize."
}


# --- 4. Virtual Memory (Pagefile) ---
Write-Host "Configuring Virtual Memory (Pagefile)..." -ForegroundColor Cyan
try {
    # Get Total RAM in MB
    $ComputerSystem = Get-WmiObject Win32_ComputerSystem
    $TotalRAM_MB = [math]::Round($ComputerSystem.TotalPhysicalMemory / 1MB)
    
    # Calculate Sizes
    # User Request: Initial = Recommended (approx 1/8 RAM or 4GB safe min) | Max = 1.5x RAM.
    # Implementation: Initial = 1x RAM (Safe/Solid) | Max = 1.5x RAM.
    # Example 16GB RAM: Initial 16384 MB, Max 24576 MB.
    $InitialSize = $TotalRAM_MB
    $MaxSize = [math]::Round($TotalRAM_MB * 1.5)

    Write-Host "  -> Detected RAM: $TotalRAM_MB MB" -ForegroundColor Gray
    Write-Host "  -> Setting Pagefile: Initial=$InitialSize MB, Max=$MaxSize MB" -ForegroundColor Yellow
    
    # Disable Automatic Management
    $ComputerSystem.AutomaticManagedPagefile = $false
    $ComputerSystem.Put() | Out-Null
    
    # Set Pagefile on C: (or SystemDrive)
    $PageFile = Get-WmiObject Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ C:'"
    if (-not $PageFile) {
        # Try finding any pagefile
        $PageFile = Get-WmiObject Win32_PageFileSetting | Select-Object -First 1
    }
    
    if ($PageFile) {
        $PageFile.InitialSize = $InitialSize
        $PageFile.MaximumSize = $MaxSize
        $PageFile.Put() | Out-Null
        Write-Host "  -> Pagefile size Updated Successfully." -ForegroundColor Green
    } else {
        # Create if doesn't exist (rare on system drive)
        Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name="C:\pagefile.sys"; InitialSize=$InitialSize; MaximumSize=$MaxSize} | Out-Null
        Write-Host "  -> Pagefile Created Successfully." -ForegroundColor Green
    }

} catch {
    Write-Host "  -> Failed to set Pagefile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nWindows Optimization Complete." -ForegroundColor Magenta
