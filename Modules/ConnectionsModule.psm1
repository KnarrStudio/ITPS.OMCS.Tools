#!/usr/bin/env powershell
#requires -Version 3.0 

function Test-AdWorkstationConnections
{
  <#
      .SYNOPSIS
      Pulls a list of computers from AD and then 'pings' them.  

      .DESCRIPTION
      Pulls a list of computers from AD based on the searchbase you pass and stores them in a csv file.  Then it reads the file and 'pings' each name in the file.  If the computer does not respond, it will log it into another csv file report.     

      .PARAMETER ADSearchBase
      Defines where you want to search such as - 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net'

      .PARAMETER WorkstationReportFolder
      This is the folder where you want the output to be stored such as  - '\\server\share\Reports\WorkstationReport' or 'c:\temp'

      .PARAMETER OutputFileName
      The name of the file.  Actually base name of the file.  Passing 'AdDesktop' will result in the following file names - '20191112-1851-AdDesktop_List.csv' and '20191112-1851-AdDesktop_Report.csv'

      .PARAMETER Bombastic
      Is a synonym for verose.  It doesn't quite do verbose, but gives you an output to the screen.  Without it you only the the report.  Does you verbose when running as a job. 

      .EXAMPLE
      Test-AdWorkstationConnections -ADSearchBase Value -WorkstationReportFolder Value -OutputFileName Value -Bombastic
    
      This will give you two files a list and a report. Plus it will give you a count of the computers found and reported with a link the report file.


      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      https://knarrstudio.github.io/ITPS.OMCS.Tools/

      https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .INPUTS
      None other than the parameters

      .OUTPUTS
      The default information in the help file will produce the following:
      \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_Report.csv
      \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_List.csv

      ------------------ Bombasistic Output ----------
      Total workstations found in AD: 32
      Total workstations not responding: 5
      This test was run by myusername from Workstation-1
      You can find the full report at: \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_Report.csv

  #>

  [CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact = 'Low')]
  param(

    [Parameter(Mandatory = $false, Position = 1)]
    [String]
    $ADSearchBase = 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net',
    
    [Parameter(Mandatory = $false, Position = 0)]
    [String]
    $WorkstationReportFolder = "$env:temp/Reports/WorkstationReport",

    [Parameter(Mandatory = $false, Position = 2)]
    [string]
    $OutputFileName = 'AdDesktop',
    
    [Switch]$Bombastic
  )
  
  $i = 1
  $BadCount = 0
  $DateNow = Get-Date -UFormat %Y%m%d-%H%M
  $OutputFileNameReport = ('{0}\{1}-{2}_Report.csv' -f $WorkstationReportFolder, $DateNow, $OutputFileName)
  $WorkstationSiteList = ('{0}\{1}-{2}_List.csv' -f $WorkstationReportFolder, $DateNow, $OutputFileName)
  
  
  if(!(Test-Path -Path $WorkstationReportFolder))
  {
    New-Item -Path $WorkstationReportFolder -ItemType Directory
  }
  
  if((Get-Module -Name ActiveDirectory))
  {
    Get-ADComputer -filter * -SearchBase $ADSearchBase -Properties * |
    Select-Object -Property Name, LastLogonDate, Description |
    Sort-Object -Property LastLogonDate -Descending |
    Export-Csv -Path $WorkstationSiteList -NoTypeInformation
  }
  Else
  {
    $OutputFileName = (Get-ChildItem -Path $OutputFileName |
      Sort-Object -Property LastWriteTime |
    Select-Object -Last 1).Name
    $WorkstationSiteList = ('{0}\{1}' -f $WorkstationReportFolder, $OutputFileName)
    Write-Warning -Message ('This is being run using the AD report from {0}' -f $OutputFileName)
  }
  
  $WorkstationList = Import-Csv -Path $WorkstationSiteList -Header Name
  $TotalWorkstations = $WorkstationList.count -1
  
  if($TotalWorkstations -gt 0)
  {
    foreach($OneWorkstation in $WorkstationList)
    {
      $WorkstationName = $OneWorkstation.Name
      if ($WorkstationName -ne 'Name')
      {
        Write-Progress -Activity ('Testing {0}' -f $WorkstationName) -PercentComplete ($i / $TotalWorkstations*100)
        $i++
        $Ping = Test-Connection -ComputerName $WorkstationName -Count 1 -Quiet
        if($Ping -ne 'True')
        {
          $BadCount ++
          $WorkstationProperties = Get-ADComputer -Identity $WorkstationName -Properties * | Select-Object -Property Name, LastLogonDate, Description
          if($BadCount -eq 1)
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileNameReport -NoClobber -NoTypeInformation
          }
          else
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileNameReport -NoTypeInformation -Append
          }
        }
      }
    }
  }
  
  if ($Bombastic)
  {
    Write-Host -Object ('Total workstations found in AD: {0}' -f $TotalWorkstations) -ForegroundColor Green
    Write-Host -Object ('Total workstations not responding: {0}' -f $BadCount) -ForegroundColor Red
    Write-Host -Object "This test was run by $env:USERNAME from $env:COMPUTERNAME"
    Write-Host -Object ('You can find the full report at: {0}' -f $OutputFileNameReport)
  }
}

function Test-FiberSatellite
{
  <#
    Archived/disabled stub of Test-FiberSatellite

    The full implementation was moved to `Modules\_Archived\Test-FiberSatellite.psm1`
    to keep the active module surface area small. If you need to restore the
    function, copy the implementation from the archived file back into this
    module or dot-source the archived file.
  #>

  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [String[]] $Sites = @(),
    [Switch] $Simple,
    [Switch] $Log,
    [String] $ReportFile,
    [String] $ReportCsv
  )

  Write-Warning 'Test-FiberSatellite is archived. See Modules\_Archived\Test-FiberSatellite.psm1 for the original implementation.'
}



