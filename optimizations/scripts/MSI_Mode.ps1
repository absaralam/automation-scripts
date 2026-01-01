<#
.SYNOPSIS
    Automated MSI Mode Enabler for GPU, Network, USB, and SATA.
.DESCRIPTION
    1. Detects compatible hardware (RTX GPU, Realtek LAN, xHCI USB, SATA AHCI).
    2. Enables Message Signaled Interrupts (MSI) in the Registry.
    3. Sets Interrupt Priority (High for GPU/Net, Normal for others).
#>

$ErrorActionPreference = "Stop"

function Set-MSIMode {
    param (
        [string]$PnpDeviceID,
        [string]$Name,
        [int]$Priority = 0 # 0=Undefined, 3=High
    )

    if ([string]::IsNullOrWhiteSpace($PnpDeviceID)) { return }

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$PnpDeviceID\Device Parameters\Interrupt Management"
    Write-Host "Targeting: $Name" -ForegroundColor Cyan

    # --- 1. Enable MSI ---
    $MSIKey = "$RegPath\MessageSignaledInterruptProperties"
    if (!(Test-Path $MSIKey)) { New-Item -Path $MSIKey -Force | Out-Null }

    $CurrentMSI = Get-ItemProperty -Path $MSIKey -Name "MSISupported" -ErrorAction SilentlyContinue
    if ($null -eq $CurrentMSI -or $CurrentMSI.MSISupported -ne 1) {
        Set-ItemProperty -Path $MSIKey -Name "MSISupported" -Value 1
        Write-Host "  -> [Fixed] MSI Mode Enabled." -ForegroundColor Yellow
    } else {
        Write-Host "  -> [OK] MSI Mode already enabled." -ForegroundColor Green
    }

    # --- 2. Set Priority ---
    # Only set priority if requested (Priority > 0). If 0, leave as is or undefined.
    if ($Priority -gt 0) {
        $AffinityKey = "$RegPath\Affinity Policy"
        if (!(Test-Path $AffinityKey)) { New-Item -Path $AffinityKey -Force | Out-Null }

        $CurrentPrio = Get-ItemProperty -Path $AffinityKey -Name "DevicePriority" -ErrorAction SilentlyContinue
        if ($null -eq $CurrentPrio -or $CurrentPrio.DevicePriority -ne $Priority) {
            Set-ItemProperty -Path $AffinityKey -Name "DevicePriority" -Value $Priority
            Write-Host "  -> [Fixed] Priority set to High ($Priority)." -ForegroundColor Yellow
        } else {
            Write-Host "  -> [OK] Priority is already High." -ForegroundColor Green
        }
    }
}

Write-Host "Starting System Optimization..." -ForegroundColor Magenta

# 1. GPU (NVIDIA/AMD) -> High Priority
$GPU = Get-CimInstance Win32_VideoController | Where-Object { $_.PNPDeviceID -like "PCI\*" } | Sort-Object RAMRam -Descending | Select-Object -First 1
if ($GPU) {
    Set-MSIMode -PnpDeviceID $GPU.PNPDeviceID -Name "GPU: $($GPU.Name)" -Priority 3
}

# 2. Network (Realtek/Intel - Physical) -> High Priority
# Filter for physical adapters (PNPDeviceID starts with PCI)
$Net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PNPDeviceID -like "PCI\*" -and $_.PhysicalAdapter -eq $true }
foreach ($n in $Net) {
    Set-MSIMode -PnpDeviceID $n.PNPDeviceID -Name "LAN: $($n.Name)" -Priority 3
}

# 3. USB Controllers (xHCI) -> Normal Priority (Undefined)
# Filter for names containing 'xHCI' OR 'eXtensible' (which implies xHCI)
$USB = Get-CimInstance Win32_USBController | Where-Object { $_.PNPDeviceID -like "PCI\*" -and ($_.Name -like "*xHCI*" -or $_.Name -like "*eXtensible*") }
foreach ($u in $USB) {
    Set-MSIMode -PnpDeviceID $u.PNPDeviceID -Name "USB: $($u.Name)" -Priority 0
}

# 4. SATA AHCI Controllers -> Normal Priority (Undefined)
$SATA = Get-CimInstance Win32_IDEController | Where-Object { $_.PNPDeviceID -like "PCI\*" -and $_.Name -like "*AHCI*" }
foreach ($s in $SATA) {
    Set-MSIMode -PnpDeviceID $s.PNPDeviceID -Name "SATA: $($s.Name)" -Priority 0
}

Write-Host "`nMSI Optimization Complete." -ForegroundColor Magenta
