#requires -Version 3.0 -Modules ITPS.OMCS.Tools
<#
    .SYNOPSIS
    Use this to run the daily checks.  

    .DESCRIPTION
    Use this to run the daily checks.  It uses the "MyLocalParameters.txt" file and splat to set the parameters for each of the modules.
    Modify the "MyLocalParameters.txt" file to complete the 

    .EXAMPLE
    Start-DailyChecks

#>


# Finding localpath of script
# $scriptDir = $PSScriptRoot

# Setting the file and path to a variable
#$MyLocalParameters = "$PSScriptRoot\MyLocalParameters.txt"
$MyLocalParameters = ".\MyLocalParameters.txt"

if($erik -ne 1)
{
  Write-Host "Edit the '$MyLocalParameters' file" -ForegroundColor Cyan
  Return  # To run, delete this line of code.
}
 
Invoke-Expression -Command (Get-Content $MyLocalParameters | Out-String )
Clear-Host


If(Test-FiberSatellite)
{
Test-FiberSatellite @FiberSatellite
}
 
If($InstalledSoftware)
{
  Get-InstalledSoftware @InstalledSoftware
}

If($PrinterStatus)
{
  Test-PrinterStatus @PrinterStatus
}
  
Test-AdWorkstationConnections @AdWorkstationConnections
#Import-Csv -Path WorkstationList | Get-UpTime -ShowOfflineComputers -DisplayOnly


