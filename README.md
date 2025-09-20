# ITPS.OMCS.Tools
### IT PowerShell Open Minded Common Sense Tools
#### (No connection to the MIT OMCS project)

This is the second go around of some tools. The first was a bunch of scripts; this one, although different in not just the exact scripts, has been written with a module-first approach.

The original idea was to create a series of tools that could be used by the desk-side support tech, but during testing I found that having to make sure the script was signed and had to "Run-As" an administrator was a blocker. Moving forward, scripts will be signed where appropriate, but the intent is for tools to be usable by a normal user where possible.

### What changed
- The repository is organized around small, focused modules in the `Modules/` folder and lightweight scripts in `Scripts/`.
- Logging and file-creation utilities have been consolidated into `Modules/LoggingModule.psm1`.
- Deprecated or duplicate scripts have been archived under `Copy/` (see `Copy/ScriptsBackup/old_deprecated/` and `Copy/_Archived/`) so the active tree stays tidy but historical copies are preserved.

### Modules
- `Modules/LoggingModule.psm1` — Centralized logging utilities:
  - `New-TimeStampFile` / `New-TimeStampFileName` — create timestamped filenames or create files with a timestamp in the name.
  - `Write-CsvReport` — append or create CSV report files from objects.
  - `Write-ReportLog` — create a monthly log file with a summary report.
- `Modules/SystemInfoModule.psm1` — system inspection helpers (including `Get-SystemUpTime` refactored to support local or remote computers via `ComputerName` or `CimSession`).
- `Modules/PrintersModule.psm1` — printer-related helpers and checks.
- `Modules/ConnectionsModule.psm1` — AD and network connection helpers (e.g. `Test-AdWorkstationConnections`).
- `Modules/FoldersModule.psm1` — folder and redirection helpers (e.g. `Repair-FolderRedirection`).

### Scripts (active)
- `Scripts/Compare-Folders.ps1` — compare files in two folders and report differences.
- `Scripts/Ping-Function.ps1` — small helper to test connectivity.
- `Scripts/Repair-FolderRedirection.ps1` — registry changes to repair redirected folders for known profiles.
- `Scripts/Repair-WindowsUpdate.ps1` — repair helpers for Windows Update components.
- `Scripts/Start-DailyChecks.ps1` — orchestrator to run daily health checks.
- `Scripts/Test-AdWorkstationConnections.ps1` — collect workstation reachability and DNS checks.
- `Scripts/Test-DfsReplication.ps1` — DFS replication checks.
- `Scripts/Write-ToConsole.ps1` — console helper utilities.
- `Scripts/Init/init.ps1` — repository initialization helpers used by the loader.

### Repo tools and tests
- `RepoTools/` — utilities used to build or publish the module (for example `Publish-Install.ps1` and `Update-ManifestModule.ps1`).
- `ITPS.OMCS.Tools.psd1` — module manifest (kept static; use `RepoTools/Update-ManifestModule.ps1` to regenerate/update).
- `tests/smoke/` — lightweight smoke tests (e.g. `smoke_test_logging.ps1`) used to validate basic module behaviors.

### Archives and backups
Deprecated or duplicate scripts that were replaced by module implementations have been moved into `Copy/` to keep the active tree clean:
- `Copy/ScriptsBackup/old_deprecated/` — historical script backups of removed files.
- `Copy/_Archived/` — higher-level archival notes and any final backups prior to permanent deletion.

If you need a removed script restored, look in the `Copy/` subtree; everything moved there was preserved before deletion from `Scripts/`.

### Notes for maintainers
- Prefer adding small, well-documented functions to the appropriate `Modules/` file instead of creating long monolithic scripts in `Scripts/`.
- Keep `ITPS.OMCS.Tools.psd1` static; run `RepoTools/Update-ManifestModule.ps1` to update exports or nested module lists and then commit the manifest.

### Module Downloads
Latest published version is available at the PowerShell Gallery: https://www.powershellgallery.com/packages/ITPS.OMCS.Tools/

Repository: https://github.com/KnarrStudio/ITPS.OMCS.Tools


