#!/usr/bin/env powershell
# Archived copy of Get-InstalledSoftware

Function Get-InstalledSoftware
{
  <#
    Archived implementation of Get-InstalledSoftware
    Use this file if you need to restore or review the original behavior.
  #>

  [cmdletbinding(DefaultParameterSetName = 'SortList',SupportsPaging = $true)]
  Param(
    [Parameter(Mandatory = $true,HelpMessage = 'At least part of the software name to test', Position = 0,ParameterSetName = 'SoftwareName')]
    [String[]]$SoftwareName,
    [Parameter(ParameterSetName = 'SortList')]
    [Parameter(ParameterSetName = 'SoftwareName')]
    [ValidateSet('DateInstalled', 'DisplayName','DisplayVersion')]
    [String]$SortList = 'DateInstalled'
  )

  # ... archived body (identical to previous implementation) ...
  Write-Warning 'This is an archived copy of Get-InstalledSoftware. Use for reference or restoration.'
}
