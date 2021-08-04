#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility

Write-host 'ITPS.OMCS.Tools.psd1'

$Major = 1     # Changes that cause the code to operate differently or large rewrites
$minor = 12    # When an individual module or function is added
$Patch = 3     # Small updates to a function or module.  Note: This goes to zero when minor is updated
$Manifest = 9  # For each manifest module update


$SplatSettings = @{
Path = '{0}\{1}.psd1' -f $((get-item (Get-Location).Path).Parent.FullName), $((get-item (Get-Location).Path).Parent.Name)
RootModule = '.\loader.psm1'
Guid = "$(New-Guid)"
Author = 'Erik' 
CompanyName = 'Knarr Studio'
ModuleVersion = '{0}.{1}.{2}.{3}' -f $Major,$minor,$Patch,$Manifest
Description = 'IT PowerShell tools for the Open Minded Common Sense tech'
PowerShellVersion = '3.0'
NestedModules = @('Modules\ConnectionsModule.psm1', 'Modules\FoldersModule.psm1', 'Modules\PrintersModule.psm1', 'Modules\SystemInfoModule.psm1')
FunctionsToExport = 'Repair-WindowsUpdate','Get-SystemUpTime', 'Get-InstalledSoftware', 'Test-PrinterStatus', 'Add-NetworkPrinter', 'Test-SQLConnection', 'Write-Report', 'Test-AdWorkstationConnections', 'Test-FiberSatellite', 'Test-Replication', 'Compare-Folders', 'Set-FolderRedirection', 'Get-FolderRedirection'#CmdletsToExport = '*'
#ModuleList = '.\ITPS.OMCS.CodingFunctions.psm1'
ReleaseNotes = 'Fixing the manifest update script'
}

New-ModuleManifest @SplatSettings