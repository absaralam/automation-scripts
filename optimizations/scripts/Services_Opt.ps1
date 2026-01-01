<#
.SYNOPSIS
    Windows Services Optimization (Chris Titus Tech "Set Services to Manual" Port).
.DESCRIPTION
    Sets non-essential services to Manual (start on demand) or Disabled.
    Based on the "Essential Tweaks" from WinUtil.
#>

$ErrorActionPreference = "SilentlyContinue"
Write-Host "Starting Services Optimization (CTT Style)..." -ForegroundColor Magenta

# --- Services to MANUAL (148 Services) ---
# These services are safe to turn off but will start if Windows needs them.
$ManualServices = @(
    "ALG", "AppMgmt", "AppReadiness", "Appinfo", "AxInstSV", "BDESVC", "BTAGService", 
    "Browser", "CDPSvc", "COMSysApp", "CertPropSvc", "CscService", "DevQueryBroker", 
    "DeviceAssociationService", "DeviceInstall", "DisplayEnhancementService", "EFS", 
    "EapHost", "FDResPub", "FrameServer", "FrameServerMonitor", "GraphicsPerfSvc", 
    "HvHost", "IKEEXT", "InstallService", "InventorySvc", "IpxlatCfgSvc", "KtmRm", 
    "LicenseManager", "LxpSvc", "MSDTC", "MSiSCSI", "McpManagementService", 
    "MicrosoftEdgeElevationService", "MsKeyboardFilter", "NaturalAuthentication", 
    "NcaSvc", "NcbService", "NcdAutoSetup", "NetSetupSvc", "Netman", "NlaSvc", 
    "PcaSvc", "PeerDistSvc", "PerfHost", "PhoneSvc", "PlugPlay", "PolicyAgent", 
    "PrintNotify", "PushToInstall", "QWAVE", "RasAuto", "RasMan", "RetailDemo", 
    "RmSvc", "RpcLocator", "SCPolicySvc", "SCardSvr", "SDRSVC", "SEMgrSvc", 
    "SNMPTRAP", "SNMPTrap", "SSDPSRV", "ScDeviceEnum", "SensorDataService", 
    "SensorService", "SensrSvc", "SessionEnv", "SharedAccess", "SmsRouter", 
    "SstpSvc", "StiSvc", "StorSvc", "TapiSrv", "TieringEngineService", "TokenBroker", 
    "TroubleshootingSvc", "TrustedInstaller", "UmRdpService", "UsoSvc", "VSS", 
    "W32Time", "WEPHOSTSVC", "WFDSConMgrSvc", "WMPNetworkSvc", "WManSvc", 
    "WPDBusEnum", "WalletService", "WarpJITSvc", "WbioSrvc", "WdiServiceHost", 
    "WdiSystemHost", "WebClient", "Wecsvc", "WerSvc", "WiaRpc", "WinRM", "WpcMonSvc", 
    "WpnService", "XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc", 
    "autotimesvc", "bthserv", "camsvc", "cloudidsvc", "dcsvc", "defragsvc", "diagsvc", 
    "dmwappushservice", "dot3svc", "edgeupdate", "edgeupdatem", "fdPHost", "fhsvc", 
    "hidserv", "icssvc", "lfsvc", "lltdsvc", "lmhosts", "netprofm", 
    "perceptionsimulation", "pla", "seclogon", "smphost", "svsvc", "swprv", 
    "upnphost", "vds", "vmicguestinterface", "vmicheartbeat", "vmickvpexchange", 
    "vmicrdv", "vmicshutdown", "vmictimesync", "vmicvmsession", "vmicvss", 
    "wbengine", "wcncsvc", "webthreatdefsvc", "wercplsupport", "wisvc", "wlidsvc", 
    "wlpasvc", "wmiApSrv", "workfolderssvc", "wuauserv"
)

# --- Services to DISABLED (11 Services) ---
# Telemetry, Remote Access, and other bloat.
$DisabledServices = @(
    "AppVClient", "AssignedAccessManagerSvc", "DiagTrack", "DialogBlockingService", 
    "NetTcpPortSharing", "RemoteAccess", "RemoteRegistry", "UevAgentService", 
    "shpamsvc", "ssh-agent", "tzautoupdate"
)

Write-Host "Setting $($ManualServices.Count) services to MANUAL..." -ForegroundColor Cyan
foreach ($Service in $ManualServices) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Set-Service -Name $Service -StartupType Manual -ErrorAction SilentlyContinue
    }
}

Write-Host "Setting $($DisabledServices.Count) services to DISABLED..." -ForegroundColor Cyan
foreach ($Service in $DisabledServices) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

Write-Host "`nServices Optimized." -ForegroundColor Magenta
