# Gaming Optimization

A modular automation suite for Windows 10/11, focused on reducing latency and removing bloat for competitive gaming.

## 🚀 Usage
1.  **Run `install_optimizations.bat` as Administrator.**
2.  Follow any on-screen prompts (none should appear; it's fully automated).
3.  **Restart your computer** after completion.

## 📂 File Structure
*   **`install_optimizations.bat`**: The main launcher. Run this.
*   **`scripts/`**: Contains the individual modules:
    *   `Windows_Opt.ps1`: Power plans, Registry tweaks, Timer Resolution.
    *   `Network_Opt.ps1`: TCP optimization, Disable Nagle/throttling, Prefer IPv4.
    *   `Input_Opt.ps1`: Disable Mouse Acceleration, Sticky Keys.
    *   `Gaming_Opt.ps1`: Game Mode, FSO, MSI Mode, Disable Hibernation.
    *   `General_Prefs.ps1`: Visuals, Explorer Tweaks, Disable Copilot/Recall.
    *   `Services_Opt.ps1`: Disables unnecessary services (SysMain, Maps, etc.).
    *   `Bloat_Remove.ps1`: Removes Microsoft Store junk (Candy Crush, etc.).
    *   `Cleanup_Opt.ps1`: Clears Temp/Prefetch files.
    *   `ISLC.ps1`: Installs Intelligent Standby List Cleaner.
    *   `MSI_Mode.ps1`: Utility to forced MSI mode on GPU/NIC.

## ⚠️ Notes
*   **Bloat Removal**: `Bloat_Remove.ps1` targets specific junk apps. Edit it if you want to keep/remove more.
*   **Safety**: Services are set to "Manual" rather than "Disabled" where possible to avoid breaking Windows Updates.
