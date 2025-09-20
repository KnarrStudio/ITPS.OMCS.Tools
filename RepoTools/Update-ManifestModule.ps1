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
NestedModules = @(Get-ChildItem -Path (Join-Path $PSScriptRoot '..\Modules') -Filter '*.psm1' | ForEach-Object { "Modules\\$($_.Name)" })
FunctionsToExport = @(Get-ChildItem -Path (Join-Path $PSScriptRoot '..\Modules') -Filter '*.psm1' | ForEach-Object {
	# Simple heuristic: parse exported function names from each module file
	$content = Get-Content $_.FullName -ErrorAction SilentlyContinue
	($content | Select-String -Pattern 'Export-ModuleMember -Function' -SimpleMatch | ForEach-Object {
		($_ -split '-Function')[1] -replace '[^A-Za-z0-9, _-]', '' -replace '\\s+', ' '
	})
} | Where-Object { $_ } | ForEach-Object { ($_ -split ',') } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Sort-Object -Unique)
#CmdletsToExport = '*'
#ModuleList = '.\ITPS.OMCS.CodingFunctions.psm1'
ReleaseNotes = 'Fixing the manifest update script'
}

New-ModuleManifest @SplatSettings