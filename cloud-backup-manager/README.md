# Cloud Backup Manager

A "zero-dependency" backup tool that automatically manages Rclone to sync your local archives to Cloud Storage.

## ⚡ Features
*   **Universal Installer**: Installs `rclone` to `%LOCALAPPDATA%` and adds it to your **System PATH** (so you can type `rclone` in any terminal).
*   **Guided Setup**: Detects missing configuration and launches the Rclone wizard.
*   **One-Click Sync**: Syncs `%USERPROFILE%\Documents\Archives` to `gdrive:Backups`.

## 📖 Usage
### Method A: Fresh Setup
1.  **Run**: Double-click `Cloud_Backup.bat`.
2.  **Follow Prompts**: It will check Rclone and launch the setup wizard to link Google Drive.

### Method B: Zero-Touch (Pro)
1.  **Export**: Copy your `rclone.conf` (usually in `%APPDATA%\rclone\`) to the script folder.
2.  **Run**: Double-click `Cloud_Backup.bat`. It will auto-install Rclone, import your keys, and start syncing instantly.

## 🕒 Automation (Scheduler)
The tool includes a built-in scheduler to run silently in the background.
1.  Run `Cloud_Backup.bat`.
2.  Choose **Option 2** ("Install Weekly Schedule").
3.  **Done!** Your archives will now automatically sync every **Sunday at 8:00 PM**.
    *   *Note: Verification logs are saved to `%LOCALAPPDATA%\Programs\rclone\backup.log`.*

### Cleaning Up
*   **Uninstall Schedule**: Choose **Option 3** in the menu.
*   **Full Uninstall**: Choose **Option 4** to completely remove Rclone, your keys, logs, and the schedule (Factory Reset).
