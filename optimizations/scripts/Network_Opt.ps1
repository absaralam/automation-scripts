<#
.SYNOPSIS
    Deep Network Optimizations for Latency (Phase 3).
.DESCRIPTION
    1. Tuning Global TCP/IP Stack (Netsh) for Gaming.
       - Disables Auto-Tuning (Buffer Bloat fix).
       - Disables RSC (Receive Segment Coalescing).
       - Enables RSS (Receive Side Scaling).
    2. Optimizes Network Adapter Advanced Properties.
       - Disables Energy Efficient Ethernet (EEE).
       - Disables Flow Control.
       - Disables Interrupt Moderation.
       - Disables Jumbo Packet.
#>

$ErrorActionPreference = "Stop"
Write-Host "Starting Deep Network Optimizations..." -ForegroundColor Magenta

# --- 1. Global TCP/IP Stack BOOSTER (Netsh) ---
Write-Host "Tuning Global TCP Stack..." -ForegroundColor Cyan

# Disable TCP Auto-Tuning (Fixes buffer bloat/latency spikes for gaming)
netsh int tcp set global autotuninglevel=disabled
Write-Host "  -> Auto-Tuning Disabled." -ForegroundColor Yellow

# Disable RSC (Receive Segment Coalescing) - MAJOR LATENCY KILLER
netsh int tcp set global rsc=disabled
Write-Host "  -> Global RSC Disabled." -ForegroundColor Yellow

# Enable RSS (Receive Side Scaling) - Uses multiple CPU cores for network
netsh int tcp set global rss=enabled
Write-Host "  -> RSS Enabled." -ForegroundColor Yellow

# Disable Windows Heuristics (Stops Windows from untuning our settings)
netsh int tcp set heuristics disabled
Write-Host "  -> Heuristics Disabled." -ForegroundColor Yellow

# Disable ECN (Explicit Congestion Notification) - Can cause packet loss on some routers
netsh int tcp set global ecncapability=disabled
Write-Host "  -> ECN Disabled." -ForegroundColor Yellow

# Disable Timestamps (Saves 12 bytes per packet header)
netsh int tcp set global timestamps=disabled
Write-Host "  -> Timestamps Disabled." -ForegroundColor Yellow

# Disable Teredo Tunneling (Major Latency Fix for IPv4 Networks)
netsh interface teredo set state disabled
Write-Host "  -> Teredo Tunneling Disabled." -ForegroundColor Yellow

# Prefer IPv4 over IPv6 (CTT / Hex 0x20 = Decimal 32)
# This forces Windows to use IPv4 for DNS/Connections first, avoiding bad IPv6 routing.
$TcpIp6Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
if (!(Test-Path $TcpIp6Path)) { New-Item -Path $TcpIp6Path -Force | Out-Null }
Set-ItemProperty -Path $TcpIp6Path -Name "DisabledComponents" -Value 32 -Type DWord -ErrorAction SilentlyContinue
Write-Host "  -> Preference set to IPv4 (Stable)." -ForegroundColor Yellow


# --- 2. Adapter-Specific Tweaks (PowerShell) ---
Write-Host "`nOptimizing Network Adapters (Hardware Level)..." -ForegroundColor Cyan

# Get Physical Adapters (Broad Filter)
$Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -or $_.Name -like "*Ethernet*" -or $_.Name -like "*Wi-Fi*" } 

foreach ($Nic in $Adapters) {
    Write-Host "Targeting: $($Nic.Name)" -ForegroundColor Green

    # 2a. Disable RSC (Hardware Offload)
    try {
        Disable-NetAdapterRsc -Name $Nic.Name -ErrorAction SilentlyContinue
        Write-Host "  -> [Driver] RSC Offload Disabled." -ForegroundColor Yellow
    } catch {
        Write-Host "  -> [Info] Driver RSC already disabled or not supported." -ForegroundColor DarkGray
    }

    # Helper function to safely set advanced properties
    function Set-AdvancedProp {
        param ($Name, $KeywordPattern, $ValueDisplay)
        $Prop = Get-NetAdapterAdvancedProperty -Name $Name -RegistryKeyword $KeywordPattern -ErrorAction SilentlyContinue
        if ($Prop) {
            # Note: For some properties we need to set RegistryValue directly if DisplayValue is ambiguous
            if ($ValueDisplay -match "^\d+$") {
                 Set-NetAdapterAdvancedProperty -Name $Name -RegistryKeyword $KeywordPattern -RegistryValue $ValueDisplay -ErrorAction SilentlyContinue
            } else {
                 Set-NetAdapterAdvancedProperty -Name $Name -RegistryKeyword $KeywordPattern -DisplayValue $ValueDisplay -ErrorAction SilentlyContinue
            }
            Write-Host "  -> [Driver] $KeywordPattern set to $ValueDisplay." -ForegroundColor Yellow
        }
    }

    # --- Power Saving Features (KILL THEM ALL) ---
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*EEE" -ValueDisplay "0"                  # Energy-Efficient Ethernet
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "EnableGreenEthernet" -ValueDisplay "0"   # Green Ethernet
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "GigaLite" -ValueDisplay "0"              # Gigabit Lite
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "PowerSavingMode" -ValueDisplay "0"       # Power Saving Mode
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*SelectiveSuspend" -ValueDisplay "0"     # Selective Suspend
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "AdvancedEEE" -ValueDisplay "0"           # Advanced EEE

    # --- Latency & Flow Control ---
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*FlowControl" -ValueDisplay "0"          # Flow Control
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*InterruptModeration" -ValueDisplay "0"  # Interrupt Moderation
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*JumboPacket" -ValueDisplay "1514"       # Jumbo Packet/Frame

    # --- Offloading (Shift to CPU for Gaming) ---
    # 0 = Disabled, 1 = Enabled (usually)
    # Disabling specific offloads helps reduces input lag in some scenarios by using the powerful main CPU.
    
    # Checksum Offloads (IPv4/TCP/UDP)
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*IPChecksumOffloadIPv4" -ValueDisplay "0"
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*TCPChecksumOffloadIPv4" -ValueDisplay "0"
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*TCPChecksumOffloadIPv6" -ValueDisplay "0"
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*UDPChecksumOffloadIPv4" -ValueDisplay "0"
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*UDPChecksumOffloadIPv6" -ValueDisplay "0"

    # Large Send Offload (LSO) - Known to cause lag spikes
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*LsoV2IPv4" -ValueDisplay "0"
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "*LsoV2IPv6" -ValueDisplay "0"
    
    # --- Wireless Specifics (If applicable) ---
    Set-AdvancedProp -Name $Nic.Name -KeywordPattern "SmartScan" -ValueDisplay "0"             # Multimedia/Gaming Environment (Actually saves power, better off)
}

Write-Host "`nDeep Network Optimization Complete." -ForegroundColor Magenta
