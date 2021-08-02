#requires -Version 2.0 -Modules ITPS.OMCS.Tools
function Start-DailyChecks
{
  <#
    .SYNOPSIS
    Short Description
    .DESCRIPTION
    Detailed Description
    .EXAMPLE
    Start-DailyChecks
    explains how to use the command
    can be multiple lines
    .EXAMPLE
    Start-DailyChecks
    another example
    can have as many examples as you like
  #>
  Clear-Host
  Test-FiberSatellite -Sites www.yahoo.com
  Test-PrinterStatus -PrintServer Printserver -PingReportFolder \\fileshare
  Test-AdWorkstationConnections -ADSearchBase xxx -PingReportFolder \\fileshare -OutputFileName WorkstationReport
  Import-Csv -Path WorkstationList | Get-SystemUpTime -ShowOfflineComputers -DisplayOnly
}

