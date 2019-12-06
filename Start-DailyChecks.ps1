#requires -Version 2.0 -Modules ITPS.OMCS.Tools
function Start-DailyChecks
{
  <#
    .SYNOPSIS
    Use this to run the daily checks.  

    .DESCRIPTION
    Use this to run the daily checks.  It uses the "MyLocalParameters.txt" file and splat to set the parameters for each of the modules.

    .EXAMPLE
    Start-DailyChecks

  #>


  Write-Host "Edit the '.\MyLocalParameters.txt' file"
  #Return  # To run, delete this line of code.
  
  Invoke-Expression (Get-Content .\MyLocalParameters.txt | Out-String )
  #Clear-Host
  Test-FiberSatellite @FiberSatellite
  Get-InstalledSoftware @InstalledSoftware
  #Test-PrinterStatus @PrinterStatus
  #Test-AdWorkstationConnections -ADSearchBase xxx -PingReportFolder \\fileshare -OutputFileName WorkstationReport
  #Import-Csv -Path WorkstationList | Get-UpTime -ShowOfflineComputers -DisplayOnly
}

