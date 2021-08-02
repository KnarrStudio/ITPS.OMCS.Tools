#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility
$SplatSettings = @{
Path = "C:\Users\erika\Documents\GitHub\ITPS.OMCS.Tools\ITPS.OMCS.Tools.psd1"
RootModule = '.\loader.psm1'
Guid = "$(New-Guid)"
Author = 'Erik' 
CompanyName = 'Knarr Studio'
ModuleVersion = '1.12.2.8' 
Description = 'IT PowerShell tools for the Open Minded Common Sense tech'
PowerShellVersion = '3.0'
NestedModules = @('Modules\ConnectionsModule.psm1', 'Modules\FoldersModule.psm1', 'Modules\PrintersModule.psm1', 'Modules\SystemInfoModule.psm1')
FunctionsToExport = 'Repair-WindowsUpdate','Get-SystemUpTime', 'Get-InstalledSoftware', 'Test-PrinterStatus', 'Add-NetworkPrinter', 'Test-SQLConnection', 'Write-Report', 'Test-AdWorkstationConnections', 'Test-FiberSatellite', 'Test-Replication', 'Compare-Folders', 'Set-FolderRedirection', 'Get-FolderRedirection'#CmdletsToExport = '*'
#ModuleList = '.\ITPS.OMCS.CodingFunctions.psm1'
ReleaseNotes = 'Fixing the Functions to export command in the psd1'
}

New-ModuleManifest @SplatSettings

