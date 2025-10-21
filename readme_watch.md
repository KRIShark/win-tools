# README for WATCH_ADVANCED.BAT

## Overview
This script, **watch_advanced.bat**, is designed to monitor specified processes, files, or system activities on a Windows system. It provides a lightweight and automated way to perform repeated checks or execute certain actions when predefined conditions are met.

The script can be customized to monitor specific executables, directories, or log files. It is suitable for system administrators, developers, or testers who need to keep an eye on dynamic system behaviors.

## Features
- Monitors processes or files at regular intervals.
- Logs activity to a file for later review.
- Supports user-defined intervals and conditions.
- Can trigger custom actions (e.g., restart a program, run a cleanup script).
- Simple command-line execution.

## Usage
1. **Place the script** in any directory of your choice.
2. **Right-click and select** `Run as Administrator` if system-level monitoring is needed.
3. **Edit the script** to configure the following parameters:
   - **TARGET_PROCESS**: Name of the process to watch (e.g., `notepad.exe`).
   - **INTERVAL**: Delay in seconds between checks.
   - **LOG_FILE**: Path to store log entries.
4. **Run the script** by double-clicking or executing it from Command Prompt:
   ```batch
   watch_advanced.bat
   ```

## Example Configuration
To monitor if `chrome.exe` is running every 30 seconds and log results to `C:\logs\watch_log.txt`, modify the following lines in the script:
```batch
set TARGET_PROCESS=chrome.exe
set INTERVAL=30
set LOG_FILE=C:\logs\watch_log.txt
```

## Output
Logs are stored in plain text format and include timestamps for every monitoring cycle. Example log entries:
```
[2025-10-21 12:00:00] Process chrome.exe is running.
[2025-10-21 12:00:30] Process chrome.exe is not found.
```

## Notes
- You may need **administrative privileges** to monitor certain system processes.
- The script can be extended with PowerShell or VBScript commands for advanced automation.
- Compatible with Windows 10 and newer.

## License
This script is provided "as is" under the MIT License. You may freely modify, distribute, or integrate it into other tools.
