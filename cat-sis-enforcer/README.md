# Caterpillar SIS IE Mode Enforcer

A specialized utility designed to enforce **Caterpillar Service Information System (SIS)** compatibility on modern Windows environments by leveraging Microsoft Edge's IE Mode.

## 🔧 Core Features
*   **IE Mode Enforcement**: Automatically configures the Edge "Enterprise Mode Site List" to force SIS URLs to open in IE11 mode.
*   **Shortcut Hijack/Repair**: Detects desktop shortcuts for "Caterpillar SIS", "SIS 2.0", etc., and modifies them to launch via Edge in IE mode automatically.
*   **Self-Healing Persistence**: Installs a hidden system watchdog task ("IEModeWatchdog") that runs every 5 minutes to re-apply settings if Windows updates revert them.
*   **One-Click Operation**: Auto-elevates to Administrator privileges.

## 📖 Usage
1.  Run `Cat_SIS_Enforcer.bat` (it will auto-request Admin rights).
2.  Choose **Option 1** to Install/Fix.
3.  Choose **Option 2** to completely uninstall and clean up all changes.

## 🛠️ Technical Details
*   **Registry Keys**: Modifies `HKCU:\Software\Policies\Microsoft\Edge` to set `InternetExplorerIntegrationLevel`.
*   **Site List**: Generates a local XML site list at `C:\ProgramData\SIS_IE_Fix\ie_site_list.xml`.
*   **Watchdog**: A PowerShell script is generated and scheduled to maintain compliance.
