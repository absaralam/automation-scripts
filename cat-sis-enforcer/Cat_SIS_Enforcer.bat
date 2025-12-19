<# : batch portion (this comment is recognized by both batch and powershell)
@echo off
setlocal
cd /d "%~dp0"

:: Check for Admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator...
) else (
    echo Requesting Elevation...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit /b
)

:: Launch PowerShell and pass this file content to it
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~fnx0') -join \"`n\")"
exit /b
#>

# --- POWERSHELL PORTION STARTS HERE ---
<#
.SYNOPSIS
    Caterpillar SIS IE Mode Enforcement Tool
.DESCRIPTION
    A self-contained tool to enforce IE Mode compliance for legacy SIS applications.
    Features:
    - Auto-elevation to Administrator.
    - Durable persistence via Hidden Scheduled Task (System context).
    - Intelligent Shortcut Hijacking (Microsoft Edge redirection).
    - Self-Healing Config (Watchdog runs every 5 mins).
    - Clean Uninstall capability.
.AUTHOR
    Absar Alam
#>

$ErrorActionPreference = "Stop"
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   SIS COMPATIBILITY MANAGER v1.0         " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "1. Install IE Mode Fix (Permanent)" -ForegroundColor Green
Write-Host "2. Uninstall / Cleanup System" -ForegroundColor Red
Write-Host "3. Exit" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

$Choice = Read-Host "Select an option (1-3)"

# --- CONFIGURATION ---
$TargetDir = "C:\ProgramData\SIS_IE_Fix"
$SiteListPath = "$TargetDir\ie_site_list.xml"
$WatchdogPath = "$TargetDir\maintain_ie_mode.ps1"

# Shortcuts to Harden (Array - Add multiple names if needed)
$TargetShortcuts = @(
    "Caterpillar SIS.lnk",
    "SIS 2.0.lnk",
    "SIS.lnk",
    "CAT SIS.lnk"
)

# URLs (Support Wildcards)
$TargetUrls = @(
    "127.0.0.1/sisweb/servlet/cat.dcs.sis.controller.CSSISDisconnectedEntryServlet",
    "127.0.0.1/sisweb"
)


function Install-Fix {
    Write-Host "`n[INSTALLING FIX]..." -ForegroundColor Cyan

    # 1. Cleanup Old Tasks
    Unregister-ScheduledTask -TaskName "IEModeWatchdog" -Confirm:$false -ErrorAction SilentlyContinue

    # 2. Create Directory & Harden Permissions
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    # Permissions
    $Acl = Get-Acl $TargetDir
    $Acl.SetAccessRuleProtection($true, $false)
    Set-Acl $TargetDir $Acl
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($Ar)
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Builtin\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($Ar)
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Builtin\Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($Ar)
    Set-Acl $TargetDir $Acl

    # 3. Generate XML
    $XmlSiteEntries = ""
    foreach ($Url in $TargetUrls) {
        $XmlSiteEntries += @"
      <site url="$Url">
        <compat-mode>IE11</compat-mode>
        <open-in>IE11</open-in>
      </site>
"@
    }
    $XmlContent = @"
<site-list version="1">
  <created-by>Antigravity</created-by>
$XmlSiteEntries
</site-list>
"@
    $XmlContent | Out-File -FilePath $SiteListPath -Encoding UTF8 -Force

    # 4. Generate Watchdog
    # Prepare array string for embedding
    $ShortcutsString = "'" + ($TargetShortcuts -join "','") + "'"
    
    $WatchdogContent = @"
`$SiteListPath = "$SiteListPath"
`$RegistryPath = "HKCU:\Software\Policies\Microsoft\Edge"
`$LogPath = "$TargetDir\ie_mode_monitor.log"
`$ExpectedSiteListVal = "file:///$($SiteListPath -replace '\\', '/')"
`$TargetShortcuts = @($ShortcutsString)

function Log-Message {
    param ([string]`$Message)
    `$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path `$LogPath -Value "[`$TimeStamp] `$Message" -ErrorAction SilentlyContinue
}

if (-not (Test-Path `$SiteListPath)) {
    try { Set-Content -Path `$SiteListPath -Value '$($XmlContent -replace "'", "''")' -Encoding UTF8 -Force } catch {}
}

if (-not (Test-Path `$RegistryPath)) { New-Item -Path `$RegistryPath -Force | Out-Null }
Set-ItemProperty -Path `$RegistryPath -Name "InternetExplorerIntegrationLevel" -Value 1 -Type DWord
Set-ItemProperty -Path `$RegistryPath -Name "InternetExplorerIntegrationSiteList" -Value `$ExpectedSiteListVal -Type String

if (`$TargetShortcuts.Count -gt 0) {
    `$DesktopPaths = @([Environment]::GetFolderPath("Desktop"), "C:\Users\Public\Desktop")
    
    foreach (`$ShortcutName in `$TargetShortcuts) {
        if ([string]::IsNullOrWhiteSpace(`$ShortcutName)) { continue }
        
        foreach (`$Desktop in `$DesktopPaths) {
            `$ShortcutPath = Join-Path `$Desktop `$ShortcutName
            if (Test-Path `$ShortcutPath) {
                try {
                    `$WshShell = New-Object -ComObject WScript.Shell
                    `$Shortcut = `$WshShell.CreateShortcut(`$ShortcutPath)
                    if (`$Shortcut.TargetPath -notmatch "msedge.exe") {
                        `$OriginalTarget = `$Shortcut.TargetPath
                        `$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
                        if (Test-Path `$EdgePath) {
                           `$Shortcut.TargetPath = `$EdgePath
                           `$Shortcut.Arguments = "`"`$OriginalTarget`""
                           `$Shortcut.Save()
                           Log-Message "SHORTCUT FIXED: `$ShortcutName"
                        }
                    }
                } catch {}
            }
        }
    }
}
"@
    $WatchdogContent | Out-File -FilePath $WatchdogPath -Encoding UTF8 -Force

    # 5. Apply Registry
    $RegPath = "HKCU:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "InternetExplorerIntegrationLevel" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPath -Name "InternetExplorerIntegrationSiteList" -Value "file:///$($SiteListPath -replace '\\', '/')" -Type String

    # 6. Register Task (Dual Trigger Method)
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$WatchdogPath"""
    $LogonTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TimeTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
    $Settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    
    Register-ScheduledTask -TaskName "IEModeWatchdog" -Action $Action -Trigger @($LogonTrigger, $TimeTrigger) -Principal $Principal -Settings $Settings -Force | Out-Null

    # 7. Start Task
    try { Start-ScheduledTask -TaskName "IEModeWatchdog" } catch {}

    Write-Host "`nSUCCESS: IE Mode Fix Installed & Active." -ForegroundColor Green
}

function Uninstall-Fix {
    Write-Host "`n[UNINSTALLING]..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName "IEModeWatchdog" -Confirm:$false -ErrorAction SilentlyContinue
    
    $RegPath = "HKCU:\Software\Policies\Microsoft\Edge"
    Remove-ItemProperty -Path $RegPath -Name "InternetExplorerIntegrationLevel" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $RegPath -Name "InternetExplorerIntegrationSiteList" -ErrorAction SilentlyContinue
    
    if (Test-Path $TargetDir) { Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction SilentlyContinue }
    
    Write-Host "Cleanup Complete. System restored." -ForegroundColor Green
}

# --- MENU LOGIC ---
if ($Choice -eq "1") {
    Install-Fix
} elseif ($Choice -eq "2") {
    Uninstall-Fix
} else {
    Write-Host "Exiting."
}

Write-Host "`nPress Enter to close..."
Read-Host
