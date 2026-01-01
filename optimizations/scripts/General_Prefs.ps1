<#
.SYNOPSIS
    General & Quality of Life Preferences (Phase 6).
.DESCRIPTION
    1. File Explorer: Shows file extensions, Opens to "This PC".
    2. Notifications: Disables Tips/Suggestions, Welcome Experience, and Global Toasts.
    3. Accessibility: Disables Sticky Keys (Shift 5x) interruptions.
#>

$ErrorActionPreference = "Stop"
Write-Host "Applying General & Quality of Life Preferences..." -ForegroundColor Magenta

# --- 1. File Explorer Tweaks ---
Write-Host "Configuring File Explorer..." -ForegroundColor Cyan
$ExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Show File Extensions (HideFileExt = 0)
Set-ItemProperty -Path $ExplorerAdvanced -Name "HideFileExt" -Value 0 -ErrorAction SilentlyContinue

# Open File Explorer to "This PC" (LaunchTo = 1)
Set-ItemProperty -Path $ExplorerAdvanced -Name "LaunchTo" -Value 1 -ErrorAction SilentlyContinue

# Restore Classic Right-Click Menu (Windows 11)
$ClassicMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
if (!(Test-Path $ClassicMenu)) { New-Item -Path $ClassicMenu -Force | Out-Null }
if (!(Test-Path "$ClassicMenu\InprocServer32")) { New-Item -Path "$ClassicMenu\InprocServer32" -Force | Out-Null }
Set-Item -Path "$ClassicMenu\InprocServer32" -Value "" -ErrorAction SilentlyContinue

# Remove "Home" from Explorer Sidebar
$HomeGUID = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
if (Test-Path $HomeGUID) { Remove-Item -Path $HomeGUID -Recurse -Force -ErrorAction SilentlyContinue }

# Remove "Gallery" from Explorer Sidebar
$GalleryGUID = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
if (Test-Path $GalleryGUID) { Remove-Item -Path $GalleryGUID -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "  -> Explorer: Extensions Visible, Launch to This PC, Classic Context Menu, Home/Gallery Removed." -ForegroundColor Yellow


# --- 2. Notifications & Bloat ---
Write-Host "`nDisabling Notifications & Suggestions..." -ForegroundColor Cyan
$ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$PushNotifications = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"

# Disable "Get tips, tricks, and suggestions"
if (!(Test-Path $ContentDelivery)) { New-Item -Path $ContentDelivery -Force | Out-Null }
Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338389Enabled" -Value 0 -ErrorAction SilentlyContinue

# Disable "Windows Welcome Experience" (Post-update nag screen)
Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-310093Enabled" -Value 0 -ErrorAction SilentlyContinue

# Disable Global Toast Notifications (Action Center)
if (!(Test-Path $PushNotifications)) { New-Item -Path $PushNotifications -Force | Out-Null }
Set-ItemProperty -Path $PushNotifications -Name "ToastEnabled" -Value 0 -ErrorAction SilentlyContinue

# Disable Notification Center & Calendar Flyout (Nuclear Option - CTT)
$ExplorerPoliciesCU = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (!(Test-Path $ExplorerPoliciesCU)) { New-Item -Path $ExplorerPoliciesCU -Force | Out-Null }
Set-ItemProperty -Path $ExplorerPoliciesCU -Name "DisableNotificationCenter" -Value 1 -ErrorAction SilentlyContinue

Write-Host "  -> Tips, Welcome Experience, and Notification Center Removed." -ForegroundColor Yellow


# --- 3. Accessibility (Sticky Keys) ---
Write-Host "`nDisabling Sticky Keys..." -ForegroundColor Cyan
$StickyKeys = "HKCU:\Control Panel\Accessibility\StickyKeys"

# Flags = 506 (Disables the shortcut and the feature)
Set-ItemProperty -Path $StickyKeys -Name "Flags" -Value "506" -ErrorAction SilentlyContinue

Write-Host "  -> Sticky Keys Shortcut (Shift 5x) Disabled." -ForegroundColor Yellow


# --- 4. Focus Assist (Do Not Disturb) ---
Write-Host "`nConfiguring Focus Assist..." -ForegroundColor Cyan
$FocusSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
$PriorityList = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\PriorityList"

# Turn Focus Assist OFF (Allow Notifications, but we disabled them globally above anyway)
# 0 = Off, 1 = Priority Only, 2 = Alarms Only
Set-ItemProperty -Path $FocusSettings -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -ErrorAction SilentlyContinue 

# Additional Focus Assist Control Keys (QuietHours)
$FocusAssistPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\FocusAssist"
if (!(Test-Path $FocusAssistPath)) { New-Item -Path $FocusAssistPath -Force | Out-Null }
Set-ItemProperty -Path $FocusAssistPath -Name "QuietHoursEnabled" -Value 0 -ErrorAction SilentlyContinue
# Ensure "Alarms Only" or "Priority Only" is not forced active
Set-ItemProperty -Path $FocusAssistPath -Name "FocusAssistMode" -Value 0 -ErrorAction SilentlyContinue

# Disable All Automatic Rules (Gaming, Duplicating Display, etc.)
# We do this by iterating known rule GUIDs or setting specific quiet hours keys if they exist.
# A more robust way for "Fresh Install" is wiping the rules from the user profile if possible.
# Alternatively, we rely on disabling Toasts globally (`ToastEnabled = 0`) which renders Focus Assist redundant.

# Clear "Priority List" Apps
if (Test-Path $PriorityList) {
    Remove-Item -Path "$PriorityList\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  -> Focus Assist Priority List Cleared." -ForegroundColor Yellow
}


# --- 5. Tablet Mode (Force Desktop) ---
Write-Host "`nConfiguring Tablet Mode..." -ForegroundColor Cyan
$ImmersiveShell = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell"

# SignInMode: 1 = Use Desktop Mode
Set-ItemProperty -Path $ImmersiveShell -Name "SignInMode" -Value 1 -ErrorAction SilentlyContinue

# ConvertibleSlateModePromptPreference: 0 = Don't ask me and don't switch
Set-ItemProperty -Path $ImmersiveShell -Name "ConvertibleSlateModePromptPreference" -Value 0 -ErrorAction SilentlyContinue

# TabletMode: 0 = Off
Set-ItemProperty -Path $ImmersiveShell -Name "TabletMode" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Tablet Mode Disabled. Desktop Mode Enforced." -ForegroundColor Yellow


# --- 6. Multitasking (Alt+Tab) ---
Write-Host "`nConfiguring Alt+Tab Behavior..." -ForegroundColor Cyan
$ExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# MultiTaskingAltTabFilter: 3 = Open windows only
Set-ItemProperty -Path $ExplorerAdvanced -Name "MultiTaskingAltTabFilter" -Value 3 -ErrorAction SilentlyContinue

Write-Host "  -> Alt+Tab set to 'Open windows only' (No Edge Tabs)." -ForegroundColor Yellow


# --- 7. Connectivity & Features ---
Write-Host "`nConfiguring Connectivity Features..." -ForegroundColor Cyan
$PoliciesSystem = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$ClipboardPath = "HKCU:\Software\Microsoft\Clipboard"
$TerminalServer = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"

# Shared Experiences (Cross Device) -> OFF
if (!(Test-Path $PoliciesSystem)) { New-Item -Path $PoliciesSystem -Force | Out-Null }
Set-ItemProperty -Path $PoliciesSystem -Name "EnableCdp" -Value 0 -ErrorAction SilentlyContinue

$CrossDevice = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration"
if (!(Test-Path $CrossDevice)) { New-Item -Path $CrossDevice -Force | Out-Null }
Set-ItemProperty -Path $CrossDevice -Name "IsResumeAllowed" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Shared Experiences (Cross Device & Resume) Disabled." -ForegroundColor Yellow

# Clipboard History -> ON
if (!(Test-Path $ClipboardPath)) { New-Item -Path $ClipboardPath -Force | Out-Null }
Set-ItemProperty -Path $ClipboardPath -Name "EnableClipboardHistory" -Value 1 -ErrorAction SilentlyContinue
Write-Host "  -> Clipboard History Enabled." -ForegroundColor Yellow

# Remote Desktop -> OFF
Set-ItemProperty -Path $TerminalServer -Name "fDenyTSConnections" -Value 1 -ErrorAction SilentlyContinue
Write-Host "  -> Remote Desktop (RDP) Disabled." -ForegroundColor Yellow

# AutoPlay -> OFF
$AutoplayHandlers = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"
Set-ItemProperty -Path $AutoplayHandlers -Name "DisableAutoplay" -Value 1 -ErrorAction SilentlyContinue
Write-Host "  -> AutoPlay Disabled (No USB/Device Popups)." -ForegroundColor Yellow

# Download Drivers over Metered Connections -> ON
$DeviceSetup = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceSetup"
if (!(Test-Path $DeviceSetup)) { New-Item -Path $DeviceSetup -Force | Out-Null }
Set-ItemProperty -Path $DeviceSetup -Name "CostedNetworkPolicy" -Value 1 -ErrorAction SilentlyContinue
Write-Host "  -> Metered Driver Downloads Enabled (Unrestricted)." -ForegroundColor Yellow

# --- 8. Visuals (Solid Black Background) ---
Write-Host "`nSetting Background to Solid Black..." -ForegroundColor Cyan
$Desktop = "HKCU:\Control Panel\Desktop"
$Colors = "HKCU:\Control Panel\Colors"

# Remove Wallpaper Image
Set-ItemProperty -Path $Desktop -Name "Wallpaper" -Value "" -ErrorAction SilentlyContinue

# Set Background Color to Black (RGB: 0 0 0)
Set-ItemProperty -Path $Colors -Name "Background" -Value "0 0 0" -ErrorAction SilentlyContinue

# Delete Transcoded Wallpaper Cache (forces refresh on restart)
$ThemePath = "$env:APPDATA\Microsoft\Windows\Themes"
if (Test-Path "$ThemePath\TranscodedWallpaper") { Remove-Item "$ThemePath\TranscodedWallpaper" -Force -ErrorAction SilentlyContinue }
if (Test-Path "$ThemePath\CachedFiles") { Remove-Item "$ThemePath\CachedFiles" -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "  -> Background set to Solid Black (Performance)." -ForegroundColor Yellow


# --- 9. Visuals (Lock Screen Picture) ---
Write-Host "`nConfiguring Lock Screen to Default Picture..." -ForegroundColor Cyan
$ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$LockScreenCreative = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen\Creative"

# Disable Windows Spotlight (Rotating Lock Screen)
Set-ItemProperty -Path $ContentDelivery -Name "RotatingLockScreenEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ContentDelivery -Name "RotatingLockScreenOverlayEnabled" -Value 0 -ErrorAction SilentlyContinue

# Disable "Fun Facts" / Creative Content
if (!(Test-Path $LockScreenCreative)) { New-Item -Path $LockScreenCreative -Force | Out-Null }
Set-ItemProperty -Path $LockScreenCreative -Name "CreativeWinOnLockScreen" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Lock Screen set to static Picture (Spotlight Disabled)." -ForegroundColor Yellow


# --- 10. Desktop Icons (This PC & Recycle Bin) ---
Write-Host "`nShowing 'This PC' and 'Recycle Bin' on Desktop..." -ForegroundColor Cyan
$HideIcons = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
if (!(Test-Path $HideIcons)) { New-Item -Path $HideIcons -Force | Out-Null }

# {20D04FE0-3AEA-1069-A2D8-08002B30309D} = This PC
# {645FF040-5081-101B-9F08-00AA002F954E} = Recycle Bin
# 0 = Show, 1 = Hide

Set-ItemProperty -Path $HideIcons -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $HideIcons -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Desktop Icons (This PC, Recycle Bin) Enabled." -ForegroundColor Yellow


# --- 11. Start Menu (Clean App List) ---
Write-Host "`nConfiguring Start Menu..." -ForegroundColor Cyan
$ExplorerPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
$ExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

# Hide "Recommended" / Recently Added Apps
if (!(Test-Path $ExplorerPolicies)) { New-Item -Path $ExplorerPolicies -Force | Out-Null }
Set-ItemProperty -Path $ExplorerPolicies -Name "HideRecommendedSection" -Value 1 -ErrorAction SilentlyContinue

$PolicyStart = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"
if (!(Test-Path $PolicyStart)) { New-Item -Path $PolicyStart -Force | Out-Null }
Set-ItemProperty -Path $PolicyStart -Name "HideRecommendedSection" -Value 1 -ErrorAction SilentlyContinue

$PolicyEdu = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education"
if (!(Test-Path $PolicyEdu)) { New-Item -Path $PolicyEdu -Force | Out-Null }
Set-ItemProperty -Path $PolicyEdu -Name "IsEducationEnvironment" -Value 1 -ErrorAction SilentlyContinue

# Disable "Most Used Apps"
Set-ItemProperty -Path $ExplorerAdvanced -Name "Start_TrackProgs" -Value 0 -ErrorAction SilentlyContinue

# Disable "Show suggestions occasionally in Start"
Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338388Enabled" -Value 0 -ErrorAction SilentlyContinue

# Disable "Recently Opened Items" (Jump Lists)
Set-ItemProperty -Path $ExplorerAdvanced -Name "Start_TrackDocs" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Start Menu Cleaned (App List Only, No Suggestions/Recents)." -ForegroundColor Yellow


# --- 12. Taskbar (Clean & Locked) ---
Write-Host "`nConfiguring Taskbar..." -ForegroundColor Cyan
$Feeds = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"

# Disable "News and Interests" / Widgets (Win10 & Win11)
if (!(Test-Path $Feeds)) { New-Item -Path $Feeds -Force | Out-Null }
Set-ItemProperty -Path $Feeds -Name "ShellFeedsTaskbarViewMode" -Value 2 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ExplorerAdvanced -Name "TaskbarDa" -Value 0 -ErrorAction SilentlyContinue # Win11 Widgets

# Disable Search Button, Task View Button
$SearchKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (!(Test-Path $SearchKey)) { New-Item -Path $SearchKey -Force | Out-Null }
Set-ItemProperty -Path $SearchKey -Name "SearchboxTaskbarMode" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ExplorerAdvanced -Name "ShowTaskViewButton" -Value 0 -ErrorAction SilentlyContinue

# Disable "Taskbar Badges" (Notification counts)
Set-ItemProperty -Path $ExplorerAdvanced -Name "TaskbarBadges" -Value 0 -ErrorAction SilentlyContinue

# Disable "Peek to Preview" (Aero Peek)
Set-ItemProperty -Path $ExplorerAdvanced -Name "DisablePreviewDesktop" -Value 1 -ErrorAction SilentlyContinue

# Lock the Taskbar
Set-ItemProperty -Path $ExplorerAdvanced -Name "TaskbarSizeMove" -Value 0 -ErrorAction SilentlyContinue

# Replace Command Prompt with PowerShell (Win+X Menu)
Set-ItemProperty -Path $ExplorerAdvanced -Name "DontUsePowerShellOnWinX" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Taskbar Configured (Locked, No News/Badges/Peek, PowerShell Enabled)." -ForegroundColor Yellow


# --- 13. Search Settings (Privacy & Safety) ---
Write-Host "`nConfiguring Search Settings..." -ForegroundColor Cyan
$SearchSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
$SearchPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

# SafeSearch: Strict (2)
if (!(Test-Path $SearchSettings)) { New-Item -Path $SearchSettings -Force | Out-Null }
Set-ItemProperty -Path $SearchSettings -Name "SafeSearchMode" -Value 2 -ErrorAction SilentlyContinue

# Cloud Content Search: OFF
Set-ItemProperty -Path $SearchSettings -Name "IsCloudSearchEnabled" -Value 0 -ErrorAction SilentlyContinue

# Device Search History: OFF
Set-ItemProperty -Path $SearchSettings -Name "IsDeviceSearchHistoryEnabled" -Value 0 -ErrorAction SilentlyContinue

# Policy: Disable Cloud Search System-wide
if (!(Test-Path $SearchPolicies)) { New-Item -Path $SearchPolicies -Force | Out-Null }
Set-ItemProperty -Path $SearchPolicies -Name "AllowCloudSearch" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Search: SafeSearch Strict, Cloud/History Disabled." -ForegroundColor Yellow


# --- Microsoft Edge Debloat (CTT) ---
Write-Host "Debloating Microsoft Edge..." -ForegroundColor Cyan
$EdgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
$EdgeUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"

if (!(Test-Path $EdgePolicy)) { New-Item -Path $EdgePolicy -Force | Out-Null }
if (!(Test-Path $EdgeUpdate)) { New-Item -Path $EdgeUpdate -Force | Out-Null }

# Edge Update Policies
Set-ItemProperty -Path $EdgeUpdate -Name "CreateDesktopShortcutDefault" -Value 0 -ErrorAction SilentlyContinue

# Edge Browser Policies
Set-ItemProperty -Path $EdgePolicy -Name "PersonalizationReportingEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "ShowRecommendationsEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "HideFirstRunExperience" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "UserFeedbackAllowed" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "ConfigureDoNotTrack" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "AlternateErrorPagesEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "EdgeCollectionsEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "EdgeShoppingAssistantEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "MicrosoftEdgeInsiderPromotionEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "ShowMicrosoftRewards" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "WebWidgetAllowed" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "DiagnosticData" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "EdgeAssetDeliveryServiceEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $EdgePolicy -Name "WalletDonationEnabled" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Edge Debloated (Telemetry, Shopping, Rewards, Widgets Disabled)." -ForegroundColor Yellow


# --- Disable Microsoft Copilot (CTT) ---
Write-Host "Disabling Microsoft Copilot..." -ForegroundColor Cyan
$CopilotPolicy = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
$CopilotMachinePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
$CopilotShell = "HKLM:\SOFTWARE\Microsoft\Windows\Shell\Copilot"
$CopilotUser = "HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsCopilot"

if (!(Test-Path $CopilotPolicy)) { New-Item -Path $CopilotPolicy -Force | Out-Null }
if (!(Test-Path $CopilotMachinePolicy)) { New-Item -Path $CopilotMachinePolicy -Force | Out-Null }
if (!(Test-Path $CopilotShell)) { New-Item -Path $CopilotShell -Force | Out-Null }
if (!(Test-Path $CopilotUser)) { New-Item -Path $CopilotUser -Force | Out-Null }

Set-ItemProperty -Path $CopilotPolicy -Name "TurnOffWindowsCopilot" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $CopilotMachinePolicy -Name "TurnOffWindowsCopilot" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $CopilotShell -Name "IsCopilotAvailable" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $CopilotUser -Name "AllowCopilotRuntime" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ExplorerAdvanced -Name "ShowCopilotButton" -Value 0 -ErrorAction SilentlyContinue

Write-Host "  -> Microsoft Copilot Disabled (UI + Policies)." -ForegroundColor Yellow

# --- 14. Privacy Hardening (Background, Mic, Diag, Telemetry) ---
Write-Host "`nHardening Privacy Settings (ShutUp10 Style)..." -ForegroundColor Cyan
$BackgroundApps = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
$AppPrivacy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
$SystemPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$InputTIPC = "HKCU:\Software\Microsoft\Input\TIPC"
$DataCollection = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$InputPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"
$CloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$ControlPanel = "HKCU:\Control Panel"

# --- Dark Theme (CTT) ---
# Sets both Apps and System to Dark Mode
Write-Host "Enabling Dark Theme..." -ForegroundColor Cyan
$ThemePersonalize = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (!(Test-Path $ThemePersonalize)) { New-Item -Path $ThemePersonalize -Force | Out-Null }
Set-ItemProperty -Path $ThemePersonalize -Name "AppsUseLightTheme" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $ThemePersonalize -Name "SystemUsesLightTheme" -Value 0 -ErrorAction SilentlyContinue

# --- NumLock on Startup (CTT) ---
Write-Host "Enabling NumLock on Startup..." -ForegroundColor Cyan
$KeyboardUser = "HKCU:\Control Panel\Keyboard"
$KeyboardDefault = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"

if (!(Test-Path $KeyboardUser)) { New-Item -Path $KeyboardUser -Force | Out-Null }
Set-ItemProperty -Path $KeyboardUser -Name "InitialKeyboardIndicators" -Value "2" -ErrorAction SilentlyContinue

# Note: Accessing .DEFAULT requires Admin
Set-ItemProperty -Path $KeyboardDefault -Name "InitialKeyboardIndicators" -Value "2" -ErrorAction SilentlyContinue

# --- Disable Bing Search in Start Menu (CTT) ---
Write-Host "Disabling Bing Search in Start Menu..." -ForegroundColor Cyan
$SearchReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (!(Test-Path $SearchReg)) { New-Item -Path $SearchReg -Force | Out-Null }
Set-ItemProperty -Path $SearchReg -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue

# --- Disable Consumer Features (CTT) ---
# Prevents auto-install of sponsored apps (Candy Crush, etc.)
if (!(Test-Path $CloudContent)) { New-Item -Path $CloudContent -Force | Out-Null }
Set-ItemProperty -Path $CloudContent -Name "DisableWindowsConsumerFeatures" -Value 1 -ErrorAction SilentlyContinue

# --- Disable Explorer Automatic Folder Discovery (CTT) ---
# Stops Windows from guessing folder types (optimizes browsing speed)
Write-Host "Disabling Explorer Automatic Folder Discovery..." -ForegroundColor Cyan
$ShellRegistry = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell"
$Bags = "$ShellRegistry\Bags"
$BagMRU = "$ShellRegistry\BagMRU"
$AllFolders = "$ShellRegistry\Bags\AllFolders\Shell"

# 1. Reset saved folder views
Remove-Item -Path $Bags -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $BagMRU -Recurse -Force -ErrorAction SilentlyContinue

# 2. Force Generic View for all folders
if (!(Test-Path $AllFolders)) { New-Item -Path $AllFolders -Force | Out-Null }
Set-ItemProperty -Path $AllFolders -Name "FolderType" -Value "NotSpecified" -Force -ErrorAction SilentlyContinue
Write-Host "  -> Folder Discovery Disabled. (FolderType=NotSpecified)" -ForegroundColor Yellow

# Background Apps -> Disabled Globally
if (!(Test-Path $BackgroundApps)) { New-Item -Path $BackgroundApps -Force | Out-Null }
Set-ItemProperty -Path $BackgroundApps -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
# Policy Force Deny (2)
if (!(Test-Path $AppPrivacy)) { New-Item -Path $AppPrivacy -Force | Out-Null }
Set-ItemProperty -Path $AppPrivacy -Name "LetAppsRunInBackground" -Value 2 -ErrorAction SilentlyContinue

# App Diagnostics -> Force Deny (2)
Set-ItemProperty -Path $AppPrivacy -Name "LetAppsGetDiagnosticInfo" -Value 2 -ErrorAction SilentlyContinue

# Microphone Access -> Force Deny (2) (Apps cannot access Mic)
Set-ItemProperty -Path $AppPrivacy -Name "LetAppsAccessMicrophone" -Value 2 -ErrorAction SilentlyContinue

# Notifications Access -> Force Deny (2) (Apps cannot access Notifications)
Set-ItemProperty -Path $AppPrivacy -Name "LetAppsAccessNotifications" -Value 2 -ErrorAction SilentlyContinue

# Activity History -> Disabled
if (!(Test-Path $SystemPolicies)) { New-Item -Path $SystemPolicies -Force | Out-Null }
Set-ItemProperty -Path $SystemPolicies -Name "PublishUserActivities" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $SystemPolicies -Name "UploadUserActivities" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $SystemPolicies -Name "EnableActivityFeed" -Value 0 -ErrorAction SilentlyContinue

# Inking & Typing Personalization -> Disabled
if (!(Test-Path $InputTIPC)) { New-Item -Path $InputTIPC -Force | Out-Null }
Set-ItemProperty -Path $InputTIPC -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
if (!(Test-Path $InputPolicies)) { New-Item -Path $InputPolicies -Force | Out-Null }
Set-ItemProperty -Path $InputPolicies -Name "AllowInputPersonalization" -Value 0 -ErrorAction SilentlyContinue

# Telemetry -> Security/Basic (0)
if (!(Test-Path $DataCollection)) { New-Item -Path $DataCollection -Force | Out-Null }
Set-ItemProperty -Path $DataCollection -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue

# Disable PowerShell 7 Telemetry (Env Var)
[System.Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", [System.EnvironmentVariableTarget]::Machine)
Set-ItemProperty -Path $DataCollection -Name "DoNotShowFeedbackNotifications" -Value 1 -ErrorAction SilentlyContinue

# --- CTT Extra Telemetry Registry Keys ---
$ContentDelivery = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$SiufRules = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
$Wer = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"

if (Test-Path $ContentDelivery) {
    Set-ItemProperty -Path $ContentDelivery -Name "ContentDeliveryAllowed" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "OemPreInstalledAppsEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "PreInstalledAppsEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "PreInstalledAppsEverEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SilentInstalledAppsEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SystemPaneSuggestionsEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338387Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338388Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338389Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-353698Enabled" -Value 0 -ErrorAction SilentlyContinue
}

if (!(Test-Path $SiufRules)) { New-Item -Path $SiufRules -Force | Out-Null }
Set-ItemProperty -Path $SiufRules -Name "NumberOfSIUFInPeriod" -Value 0 -ErrorAction SilentlyContinue

if (Test-Path $Wer) {
    Set-ItemProperty -Path $Wer -Name "Disabled" -Value 1 -ErrorAction SilentlyContinue
}

# --- CTT Telemetry Scheduled Tasks ---
$TelemetryTasks = @(
    "Microsoft\Windows\Autochk\Proxy",
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "Microsoft\Windows\Feedback\Siuf\DmClient",
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "Microsoft\Windows\Application Experience\MareBackup",
    "Microsoft\Windows\Application Experience\StartupAppTask",
    "Microsoft\Windows\Application Experience\PcaPatchDbTask"
)

foreach ($Task in $TelemetryTasks) {
    Disable-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "  -> Privacy Hardened: Background Apps, Mic, Diag, Activity, Inking, Telemetry -> ALL DISABLED." -ForegroundColor Yellow

Write-Host "`nGeneral Preferences Applied." -ForegroundColor Magenta
