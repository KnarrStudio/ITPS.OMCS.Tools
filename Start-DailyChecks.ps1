#requires -Version 3.0 -Modules ITPS.OMCS.Tools
<#
    .SYNOPSIS
    Use this to run the daily checks.  

    .DESCRIPTION
    Use this to run the daily checks.  It uses the "MyLocalParameters.txt" file and splat to set the parameters for each of the modules.

    .EXAMPLE
    Start-DailyChecks

#>


# Finding localpath of script
# $scriptDir = $PSScriptRoot

# Setting the file and path to a variable
$MyLocalParameters = "$PSScriptRoot\MyLocalParameters.txt"

if($erik -ne 1)
{
  Write-Host "Edit the '$MyLocalParameters' file" -ForegroundColor Cyan
  Return  # To run, delete this line of code.
}
 
Invoke-Expression -Command (Get-Content $MyLocalParameters | Out-String )
#Clear-Host



Test-FiberSatellite @FiberSatellite
  
If($InstalledSoftware)
{
  Get-InstalledSoftware @InstalledSoftware
}

If($PrinterStatus)
{
  #Test-PrinterStatus @PrinterStatus
}
  
#Test-AdWorkstationConnections -ADSearchBase xxx -PingReportFolder \\fileshare -OutputFileName WorkstationReport
#Import-Csv -Path WorkstationList | Get-UpTime -ShowOfflineComputers -DisplayOnly


