function Test-PrinterStatus
{

  param
  (
    [Parameter(Mandatory = $true,HelpMessage = 'Add PrintServer name', Position = 0)]
    [string]$PrintServer,
    
    [Parameter(Mandatory = $true,HelpMessage = '\\NetworkShare\Reports\PrinterStatus or c:\temp',Position = 1)]
    [string]$PingReportFolder
  )
  
  $BadCount = 0
  $DateStamp = Get-Date -UFormat %Y%m%d-%H%M%S
  $ReportFile = (('{0}\{1}-PrinterReport.csv' -f $PingReportFolder, $DateStamp))
  $PrinterSiteList = (('{0}\{1}-FullPrinterList.csv' -f $PingReportFolder, $DateStamp))
  $i = 0
  
  if(!(Test-Path -Path $PingReportFolder))
  {
    New-Item -Path $PingReportFolder -ItemType Directory
  }
  
  Get-Printer -ComputerName $PrintServer |
  Select-Object -Property Name, PrinterStatus, DriverName, PortName, Published |
  Export-Csv -Path $PrinterSiteList -NoTypeInformation
  
  $PrinterList = Import-Csv -Path $PrinterSiteList # -Header Name
  $TotalPrinters = $PrinterList.count -1
  
  if($TotalPrinters -gt 0)
  {
    foreach($OnePrinter in $PrinterList)
    {
      $PrinterName = $OnePrinter.Name
      if ($PrinterName -ne 'Name')
      {
        $PrinterIpAddress = Get-PrinterPort -ComputerName $PrintServer -Name $PrinterName | Select-Object -Property PrinterHostAddress -ErrorAction SilentlyContinue
        if ($PrinterIpAddress)
        {
          $PingPortResult = Test-Connection -ComputerName $PrinterIpAddress -Count 1 -Quiet 
          if($PingPortResult -eq $false)
          {
            Write-Host ('The printer {0} failed to respond to a ping!  ' -f $PrinterName) -f Red
          }
          elseif($PingPortResult -eq $true)
          {
            Write-Host ('The printer {0} responded to a ping!  ' -f $PrinterName) -f Green
          }
        }
      }
      
      #Start-Sleep -Seconds .5
      Write-Progress -Activity ('Testing {0}' -f $PrinterName) -PercentComplete ($i / $TotalPrinters*100)
      $i++
      if($OnePrinter.PrinterStatus -ne 'Normal')
      {
        $BadCount ++
        $PrinterProperties = $OnePrinter
        if($BadCount -eq 1)
        {
          $PrinterProperties | Export-Csv -Path $ReportFile -NoClobber -NoTypeInformation
        }
        else
        {
          $PrinterProperties | Export-Csv -Path $ReportFile -NoTypeInformation -Append
        }
      }
    }
  }
  
  Write-Verbose -Message ('Total Printers found: {0}' -f $TotalPrinters)
  Write-Verbose -Message ('Total Printers not in a Normal Status: {0}' -f $BadCount)
  Write-Verbose -Message "This test was run by $env:USERNAME from $env:COMPUTERNAME"
  Write-Verbose -Message ('You can find the full report at: {0}' -f $ReportFile)
}