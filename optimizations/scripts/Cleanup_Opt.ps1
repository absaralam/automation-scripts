<#
.SYNOPSIS
    System Cleanup (Phase Final).
.DESCRIPTION
    Deletes Temporary Files to free up space and remove junk.
    Based on Chris Titus Tech's "Delete Temporary Files".
#>

$ErrorActionPreference = "SilentlyContinue"
Write-Host "Starting System Cleanup..." -ForegroundColor Magenta

# --- Delete Temporary Files (CTT) ---
Write-Host "Cleaning Temporary Files..." -ForegroundColor Cyan

# 1. User Temp Folder
$UserTemp = "$Env:Temp\*"
Write-Host "  -> Cleaning User Temp ($UserTemp)..." -ForegroundColor Gray
Remove-Item -Path $UserTemp -Recurse -Force -ErrorAction SilentlyContinue

# 2. Windows Temp Folder
$WinTemp = "$Env:SystemRoot\Temp\*"
Write-Host "  -> Cleaning Windows Temp ($WinTemp)..." -ForegroundColor Gray
Remove-Item -Path $WinTemp -Recurse -Force -ErrorAction SilentlyContinue

# 3. Prefetch (Optional addition, common in cleanups)
$Prefetch = "$Env:SystemRoot\Prefetch\*"
Write-Host "  -> Cleaning Prefetch ($Prefetch)..." -ForegroundColor Gray
Remove-Item -Path $Prefetch -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  -> Temporary Files Cleaned." -ForegroundColor Yellow

Write-Host "`nSystem Cleanup Complete." -ForegroundColor Magenta
