<#
.SYNOPSIS
    Selective App Removal Script (Debloat).
.DESCRIPTION
    Removes specific Microsoft Store apps defined in the $AppList array.
    Supports wildcards (e.g., "*CandyCrush*").
#>

$ErrorActionPreference = "SilentlyContinue"
Write-Host "Starting Selective App Removal..." -ForegroundColor Magenta

# --- User Defined App List ---
# Add the apps you want to remove inside this array using quotes.
$AppList = @(
    "Microsoft.Microsoft3DViewer"
    "Microsoft.AppConnector"
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingTranslator"
    "Microsoft.BingWeather"
    "Microsoft.BingFoodAndDrink"
    "Microsoft.BingHealthAndFitness"
    "Microsoft.BingTravel"
    "Microsoft.GetHelp"
    "Microsoft.GetStarted"
    "Microsoft.Messaging"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MinecraftUWP"
    "Microsoft.XboxApp"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.News"
    "Microsoft.Office.Lens"
    "Microsoft.Office.Sway"
    "Microsoft.Office.OneNote"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.Whiteboard"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsCommunicationsApps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.ConnectivityStore"
    "Microsoft.MixedReality.Portal"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.MicrosoftOfficeHub"
    "MsTeams"
    "*EclipseManager*"
    "*ActiproSoftwareLLC*"
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Twitter*"
    "*Facebook*"
    "*Royal Revolt*"
    "*Sway*"
    "*Speed Test*"
    "*Dolby*"
    "*Viber*"
    "*ACGMediaPlayer*"
    "*Netflix*"
    "*OneCalendar*"
    "*LinkedInForWindows*"
    "*HiddenCityMysteryofShadows*"
    "*Hulu*"
    "*HiddenCity*"
    "*AdobePhotoshopExpress*"
    "*HotspotShieldFreeVPN*"
    "*Microsoft.Advertising.Xaml*"
    
    # Extra Common Bloat (Added by Antigravity)
    "*Spotify*"
    "*Disney*"
    "*TikTok*"
    "*Instagram*"
    "*PrimeVideo*"
    "*Clipchamp*"
)

if ($AppList.Count -eq 0) {
    Write-Warning "App List is empty. No apps were removed."
    Write-Host "Please edit this file or tell the assistant which apps to add." -ForegroundColor Gray
    exit
}

# --- Removal Logic ---
foreach ($AppName in $AppList) {
    Write-Host "Searching for: $AppName" -ForegroundColor Cyan
    
    $Package = Get-AppxPackage -Name $AppName -AllUsers -ErrorAction SilentlyContinue

    if ($Package) {
        Write-Host "  -> Removing: $($Package.Name)" -ForegroundColor Yellow
        $Package | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Write-Host "     [Removed]" -ForegroundColor Green
    } else {
        Write-Host "  -> Not found or already removed." -ForegroundColor DarkGray
    }
}

Write-Host "`nDebloat Complete." -ForegroundColor Magenta
