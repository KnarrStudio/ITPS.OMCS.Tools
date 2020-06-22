#requires -Version 3.0 -Modules PrintManagement
function Test-PrinterStatus
{
  <#
      .SYNOPSIS
      Tests the status of the printers on the network.  

      .DESCRIPTION
      What started as a oneline script to find out which printers are erroring out has turned into this module.  It creates two files, one that has a list of all of the printers and one that has a list of the printers that are not in a "Normal" status.  It also finds the port IP Address and attempts to "ping" it.  It returns those results to the screen.


      .PARAMETER PrintServer
      Assigns the print server name to the variable.

      .PARAMETER PingReportFolder
      Assigns a location to where the files will be stored.

      .EXAMPLE
      Test-PrinterStatus -PrintServer Value -PingReportFolder Value
      The simple form of this returns the staus of the printers.  

      .LINK
      https://knarrstudio.github.io/ITPS.OMCS.Tools/
      The first link is opened by Get-Help -Online Test-PrinterStatus

      .INPUTS
      Print server Name
      Report location

      .OUTPUTS
      Screen and Files
  #>

  param
  (
    [Parameter(Mandatory ,HelpMessage = 'Add PrintServer name', Position = 0)]
    [string]$PrintServer,
    
    [Parameter(HelpMessage = '\\NetworkShare\Reports\PrinterStatus\report.csv or c:\temp\report.csv',Position = 1)]
    [string]$PingReportFolder = 'C:\temp'<#,
    
        [Parameter(Mandatory,HelpMessage = '\\NetworkShare\Reports\PrinterStatus\report.csv or c:\temp\report.csv',Position = 2)]
        [string]$PrinterStatusReport
    
    ,
    
        [Parameter(Mandatory,HelpMessage = '\\NetworkShare\Reports\PrinterStatus\report.csv or c:\temp\report.csv',Position = 2)]
        [string]$PrinterListFull
       #> 
  )
  
  #$PingReportFolder = $env:HOMEDRIVE\temp
  $BadCount = $i = 0
  $DateStampFile = Get-Date -UFormat %Y%m%d-%H%M%S
  $DateStampData = Get-Date -Format G 
  
  $PrinterStatusReport = (('{0}\{1}-PrinterReport.csv' -f $PingReportFolder, $DateStampFile))
  $PrinterSiteList = (('{0}\{1}-FullPrinterList.csv' -f $PingReportFolder, $DateStampFile))
  
  $PrinterStatus = [Ordered]@{
    'DateStamp' = $DateStampData
  }
  
  <#
      $PrinterStatus['PrinterName'] = ''
      $PrinterStatus['PrinterPort'] = ''
      $PrinterStatus['PingResponse'] = ''
      $PrinterStatus['DuplexingMode'] = ''
      $PrinterStatus['PaperSize']          = ''
      $PrinterStatus['Collate']       = ''
      $PrinterStatus['Color']         = ''
  #> 
  
  if(!(Test-Path -Path $PingReportFolder))
  {
    New-Item -Path $PingReportFolder -ItemType Directory
  }
  
  $AllPrinters = Get-Printer -ComputerName $PrintServer | Select-Object -Property *
  #$AllPrinters = Get-Printer -Name 'EPSON XP-440 Series' | Select-Object -Property *
  #$AllPrinters = Get-Printer | Select-Object -Property *
  
  # Export AllPrinters to a CSV
  $AllPrinters | Export-Csv $PrinterSiteList -NoTypeInformation
  
  $CountTotalPrinters = $AllPrinters.count
  if($CountTotalPrinters -gt 0)
  {
    foreach($OnePrinter in $AllPrinters)
    {
      $PrinterStatus['PrinterPort'] = $PortName = $OnePrinter.PortName
      $PrinterStatus['PrinterName'] = $PrinterName = $OnePrinter.Name
      Write-Verbose ('Printer/Port Name: {0} / {1}' -f $PrinterName,$PortName)
      Write-Progress -Activity ('Testing {0}' -f $PrinterName) -PercentComplete ($i / $CountTotalPrinters*100)
      $i++
      
      # Get Print Configuration
      $PrintConfig = Get-PrintConfiguration -ComputerName $PrintServer -PrinterName $PrinterName
      $PrinterStatus['DuplexingMode'] = $PrintConfig.DuplexingMode
      $PrinterStatus['PaperSize']     = $PrintConfig.PaperSize
      $PrinterStatus['Collate']       = $PrintConfig.Collate
      $PrinterStatus['Color']         = $PrintConfig.Color
      Write-Verbose ('Printer Config Status: {0}' -f $PrinterStatus)
      # Get-PrinterProperty -PrinterName 'EPSON XP-440 Series'
      # $PrintConfig = Get-PrintConfiguration -PrinterName 'EPSON XP-440 Series'
      
      $PrinterStatus['PortIpAddress'] = $PortIpAddress = (Get-PrinterPort -ComputerName $PrintServer -Name $PortName).PrinterHostAddress 
      Write-Verbose ('$Port Name / Port IP Address {0} / {1}' -f $PortName,$PortIpAddress)
      if ($PortIpAddress)
      {
        $PingPortResult = Test-NetConnection -ComputerName $PortIpAddress -InformationLevel Quiet
        Write-Verbose ('Port Address Ping Response: {0}' -f $PingPortResult)
      }
        
      Switch ($PingPortResult) {
        $False 
        {
          Write-Host -Object ('The printer {0} failed to respond to a ping!  ' -f $PrinterName) -ForegroundColor Red
          $BadCount ++
          $PrinterProperties = $OnePrinter
        }
        $True 
        {
          Write-Host -Object ('The printer {0} responded to a ping!  ' -f $PrinterName) -ForegroundColor Green
        }
        Default 
        {
          $PingPortResult = 'N/A'
        }
      }
      $PrinterStatus['PingPortResult'] = $PingPortResult
    }
      
    If($PrinterStatusReport -ne $null)
    {
      # Export the hashtable to the file
      $PrinterStatus |
      ForEach-Object -Process {
        [pscustomobject]$_
      } |
      Export-Csv -Path $PrinterStatusReport -NoTypeInformation -Force -Append
    }
  }
  
  Write-Verbose -Message ('Total Printers found: {0}' -f $CountTotalPrinters)
  Write-Verbose -Message ('Total Printers not responding to a PING: {0}' -f $BadCount)
  Write-Verbose -Message "This test was run by $env:USERNAME from $env:COMPUTERNAME"
  Write-Verbose -Message ('You can find the full report at: {0}' -f $PrinterStatusReport)
}


$PrinterSplat = @{
  'PrintServer'    = $env:COMPUTERNAME
  'PingReportFolder' = 'C:\temp'
}


Test-PrinterStatus @PrinterSplat -Verbose