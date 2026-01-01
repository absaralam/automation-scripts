<#
.SYNOPSIS
    Input Optimizations for Mouse and Keyboard (Phase 4).
.DESCRIPTION
    1. Mouse Optimizations:
       - Disables "Enhance Pointer Precision" (Acceleration).
       - Sets Windows Mouse Speed to 6/11 (1:1 Pixel Ratio, Registry Value 10).
    2. Keyboard Optimizations:
       - Sets Repeat Delay to Shortest (0).
       - Sets Repeat Rate to Fastest (31).
    Note: Requires a Logoff/Restart to apply fully.
#>

$ErrorActionPreference = "Stop"
Write-Host "Starting Input Optimizations (Mouse & Keyboard)..." -ForegroundColor Magenta

# --- 0. Display DPI Scaling (100% / 96 DPI) ---
# MarkC Fix requires exact DPI matching. We force 100% to ensure 1:1 behavior.
Write-Host "`nConfiguring Display Scaling (100%)..." -ForegroundColor Cyan
$DesktopPath = "HKCU:\Control Panel\Desktop"

# LogPixels: 96 = 100% Scaling
Set-ItemProperty -Path $DesktopPath -Name "LogPixels" -Value 96 -ErrorAction SilentlyContinue

# Win8DpiScaling: 0 = Use LogPixels (XP Style), 1 = Custom
# We set to 0 to ensure the system respects our 96 DPI setting without override artifacts
Set-ItemProperty -Path $DesktopPath -Name "Win8DpiScaling" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Display Scaling forced to 100% (96 DPI)." -ForegroundColor Yellow
Write-Host "     (Required for precise MarkC Mouse Fix behavior)" -ForegroundColor DarkGray


# --- 1. Mouse Optimizations ---
Write-Host "`nConfiguring Mouse Settings..." -ForegroundColor Cyan
$MousePath = "HKCU:\Control Panel\Mouse"

# Disable Mouse Acceleration (Enhance Pointer Precision)
Set-ItemProperty -Path $MousePath -Name "MouseSpeed" -Value "0"
Set-ItemProperty -Path $MousePath -Name "MouseThreshold1" -Value "0"
Set-ItemProperty -Path $MousePath -Name "MouseThreshold2" -Value "0"
Write-Host "  -> Mouse Acceleration Disabled." -ForegroundColor Yellow

# Set Pointer Speed to 6/11 (Registry Value 10)
# This ensures 1:1 pixel mapping (No software scaling/skipping)
Set-ItemProperty -Path $MousePath -Name "MouseSensitivity" -Value "10"
Write-Host "  -> Mouse Sensitivity set to 10 (6/11 in UI)." -ForegroundColor Yellow

# --- MarkC Mouse Fix for 1:1 Scaling (No Curve) ---
# This ensures that even if a game requests acceleration, Windows gives it linear input.
# Standard 100% Scaling Curve:
$XCurve = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00, 0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00, 0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00, 0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
$YCurve = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00, 0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00, 0x00,0x00,0xA8,0x00,0x00,0x00,0x00,0x00, 0x00,0x00,0xE0,0x00,0x00,0x00,0x00,0x00)

Set-ItemProperty -Path $MousePath -Name "SmoothMouseXCurve" -Value $XCurve
Set-ItemProperty -Path $MousePath -Name "SmoothMouseYCurve" -Value $YCurve
Write-Host "  -> MarkC Mouse Fix Applied (Linear 1:1 Curve)." -ForegroundColor Yellow


# --- 2. Keyboard Optimizations ---
Write-Host "`nConfiguring Keyboard Settings..." -ForegroundColor Cyan
$KeyboardPath = "HKCU:\Control Panel\Keyboard"

# Shortest Repeat Delay (Time before it starts repeating)
# 0 = Shortest (~250ms)
Set-ItemProperty -Path $KeyboardPath -Name "KeyboardDelay" -Value "0"
Write-Host "  -> Keyboard Delay set to 0 (Shortest)." -ForegroundColor Yellow

# Fastest Repeat Rate (How fast it repeats)
# 31 = Fastest (~30 chars/sec)
Set-ItemProperty -Path $KeyboardPath -Name "KeyboardSpeed" -Value "31"
Write-Host "  -> Keyboard Repeat Rate set to 31 (Fastest)." -ForegroundColor Yellow

Write-Host "`nInput Optimization Complete." -ForegroundColor Magenta
Write-Host "NOTE: You must RESTART your PC for input settings to take effect." -ForegroundColor Red
