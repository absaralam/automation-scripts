<#
.SYNOPSIS
    Gaming & Visual Optimizations (Phase 5).
.DESCRIPTION
    1. Visual Effects: Adjusts for Best Performance (Disables animations, etc.).
    2. Game Bar: Disables Background Recording & Overlay.
    3. Game Mode: Enables "Game Mode" prioritization.
    4. Fast Startup: Disables "Hiberboot" to force clean kernel boots.
#>

$ErrorActionPreference = "Stop"
Write-Host "Starting Gaming & Visual Optimizations..." -ForegroundColor Magenta

# --- 1. Visual Effects (Custom Performance) ---
Write-Host "Configuring Visual Effects (Performance + Smooth Fonts)..." -ForegroundColor Cyan
$VisualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$DesktopPath = "HKCU:\Control Panel\Desktop"
$WindowMetricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"

# Set "Custom" Performance Mode (So we can mix settings)
Set-ItemProperty -Path $VisualFXPath -Name "VisualFXSetting" -Value 3 -ErrorAction SilentlyContinue

# Disable Animations (Min/Max, Taskbar, ComboBox, etc.)
Set-ItemProperty -Path $WindowMetricsPath -Name "MinAnimate" -Value "0" -ErrorAction SilentlyContinue
Set-ItemProperty -Path $DesktopPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue <# Just force a known 'fast' mask #>

# explicitly ENABLE Smooth Edges of Screen Fonts (ClearType)
Set-ItemProperty -Path $DesktopPath -Name "FontSmoothing" -Value "2"
Set-ItemProperty -Path $DesktopPath -Name "FontSmoothingType" -Value 2
Write-Host "  -> Animations Disabled. Font Smoothing Enabled." -ForegroundColor Yellow

# --- 2. Game Bar & Game Mode ---
Write-Host "`nConfiguring Game Mode & Game Bar..." -ForegroundColor Cyan
$GameConfigPath = "HKCU:\Software\Microsoft\GameBar"
$GameDVRPath = "HKCU:\System\GameConfigStore"

# Disable Game Bar Overlay and App Capture
Set-ItemProperty -Path $GameConfigPath -Name "AllowAutoGameMode" -Value 1 -ErrorAction SilentlyContinue

# GameDVR Config Store (CTT + Extra optimizations)
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_FSEBehavior" -Value 2 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_EFSEFeatureFlags" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $GameDVRPath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -ErrorAction SilentlyContinue

# Additional GameDVR Keys (Comprehensive Disable)
$GameDVRPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
if (!(Test-Path $GameDVRPolicy)) { New-Item -Path $GameDVRPolicy -Force | Out-Null }
Set-ItemProperty -Path $GameDVRPolicy -Name "AllowGameDVR" -Value 0 -ErrorAction SilentlyContinue

$GameDVRKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
if (Test-Path $GameDVRKey) {
    Set-ItemProperty -Path $GameDVRKey -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
}

Write-Host "  -> Game Bar Disabled / Game Mode Enabled." -ForegroundColor Yellow


# --- 2b. CPU Priority Optimization ---
Write-Host "Optimizing CPU Priority (Win32PrioritySeparation)..." -ForegroundColor Cyan
$PriorityKey = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
# 26 Hex = 38 Decimal (Short Intervals, Variable, 3x Boost for Foreground) - Best for FPS/Latency
Set-ItemProperty -Path $PriorityKey -Name "Win32PrioritySeparation" -Value 38 -ErrorAction SilentlyContinue
Write-Host "  -> Win32PrioritySeparation set to 26 (Hex)." -ForegroundColor Yellow


# --- 3. Fast Startup & Hibernation ---
Write-Host "`nDisabling Fast Startup & Hibernation (CTT Method)..." -ForegroundColor Cyan
$PowerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$FlyoutPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings"

# 1. Disable Hiberboot (Fast Startup) - Our Tweak
if (Test-Path $PowerPath) {
    Set-ItemProperty -Path $PowerPath -Name "HiberbootEnabled" -Value 0 -ErrorAction SilentlyContinue
    # CTT Tweak: Explicitly set HibernateEnabled via Registry
    Set-ItemProperty -Path $PowerPath -Name "HibernateEnabled" -Value 0 -ErrorAction SilentlyContinue
}

# 2. CTT Tweak: Hide Configuration from Flyout Menu
if (!(Test-Path $FlyoutPath)) { New-Item -Path $FlyoutPath -Force | Out-Null }
Set-ItemProperty -Path $FlyoutPath -Name "ShowHibernateOption" -Value 0 -ErrorAction SilentlyContinue

# 3. PowerCFG Command (The Hammer)
# This clears hiberfil.sys and prevents hibernation entirely
Start-Process powercfg -ArgumentList "-h off" -NoNewWindow -Wait
Write-Host "  -> Hibernation & Fast Startup Disabled (PowerCFG + Registry)." -ForegroundColor Yellow

# --- 4. System Restore ---
Write-Host "`nDisabling System Restore..." -ForegroundColor Cyan
# Disable System Restore on the System Drive (Usually C:)
try {
    Disable-ComputerRestore -Drive $Env:SystemDrive -ErrorAction Stop
    Write-Host "  -> System Restore Disabled on $Env:SystemDrive." -ForegroundColor Yellow
} catch {
    Write-Warning "Failed to disable System Restore. Ensure you are running as Administrator."
}

# --- 5. Hardware Accelerated GPU Scheduling (HAGS) ---
Write-Host "`nEnabling Hardware Accelerated GPU Scheduling..." -ForegroundColor Cyan
$GraphicsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

Set-ItemProperty -Path $GraphicsPath -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
Write-Host "  -> HAGS Enabled (Required for DLSS FrameGen/OptiScaler)." -ForegroundColor Yellow

# Disable GameBar Presence Writer
Write-Host "Disabling GameBar Presence Writer..." -ForegroundColor Cyan
$PresenceWriterPath = "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"

if (Test-Path $PresenceWriterPath) {
    # Check if already disabled
    $CurrentVal = Get-ItemProperty -Path $PresenceWriterPath -Name "ActivationType" -ErrorAction SilentlyContinue
    if ($CurrentVal -and $CurrentVal.ActivationType -eq 0) {
        Write-Host "  -> Presence Writer already disabled." -ForegroundColor Green
    } else {
        try {
            # Try setting directly first
            Set-ItemProperty -Path $PresenceWriterPath -Name "ActivationType" -Value 0 -ErrorAction Stop
            Write-Host "  -> GameBar Presence Writer Disabled." -ForegroundColor Yellow
        } catch {
            Write-Host "  -> [Info] Presence Writer Key locked by TrustedInstaller. Skipping (Non-critical)." -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  -> Presence Writer Key not found. Skipping." -ForegroundColor DarkGray
}


# Disable Memory Compression (Saves CPU cycles, increases RAM usage)
Write-Host "Disabling Memory Compression..." -ForegroundColor Cyan
Disable-MMAgent -mc -ErrorAction SilentlyContinue
Write-Host "  -> Memory Compression Disabled." -ForegroundColor Yellow

# Disable Core Isolation / Memory Integrity (VBS/HVCI) (Critical for gaming performance)
Write-Host "Disabling Core Isolation (VBS/HVCI)..." -ForegroundColor Cyan
$DeviceGuard = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
if (!(Test-Path $DeviceGuard)) { New-Item -Path $DeviceGuard -Force | Out-Null }
Set-ItemProperty -Path $DeviceGuard -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
Write-Host "  -> Core Isolation (Memory Integrity) Disabled." -ForegroundColor Yellow

Write-Host "`nGaming Optimization Complete." -ForegroundColor Magenta
