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
      $PortName = $OnePrinter.PortName
      $PrinterName = $OnePrinter.Name
      if ($PrinterName -ne 'Name')
      {
        $PortIpAddress = (Get-PrinterPort -ComputerName $PrintServer -Name $PortName).PrinterHostAddress 
        #[String]$PortIpAddress = (Get-PrinterPort -ComputerName $PrintServer -Name $PrinterName -ErrorAction SilentlyContinue).PrinterHostAddress | Select-Object -Property PrinterHostAddress -ErrorAction SilentlyContinue
        if ($PortIpAddress)
        {
          $PingPortResult = Test-Connection -ComputerName $PortIpAddress -Count 1 -Quiet 
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




# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDp5YHguz2FV4HcV7dXiX5wNn
# C2qgggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
# AQUFADAhMR8wHQYDVQQDDBZLbmFyclN0dWRpb1NpZ25pbmdDZXJ0MB4XDTIwMDIx
# OTIyMTUwM1oXDTI0MDIxOTAwMDAwMFowITEfMB0GA1UEAwwWS25hcnJTdHVkaW9T
# aWduaW5nQ2VydDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAxtuEswl88jvC
# o69/eD6Rtr5pZikUTNGtI2LqT1a3CZ8F6BCC1tp0+ftZLppxueX/BKVBPTTSg/7t
# f5nkGMFIvbabMiYtfWTPr6L32B4SIZayruDkVETRH74RzG3i2xHNMThZykUWsekN
# jAer+/a2o7F7G6A/GlH8kan4MGjo1K0CAwEAAaNGMEQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFGp363bIyuwL4FI0q36S/8cl5MOBMA4GA1UdDwEB/wQE
# AwIHgDANBgkqhkiG9w0BAQUFAAOBgQBkVkTuk0ySiG3DYg0dKBQaUqI8aKssFv8T
# WNo23yXKUASrgjVl1iAt402AQDHE3aR4OKv/7KIIHYaiFTX5yQdMFoCyhXGop3a5
# bmipv/NjwGWsYrCq9rX2uTuNpUmvQ+0hM3hRzgZ+M2gmjCT/Pgvia/LJiHuF2SlA
# 7wXAuVRh8jGCAVUwggFRAgEBMDUwITEfMB0GA1UEAwwWS25hcnJTdHVkaW9TaWdu
# aW5nQ2VydAIQapk6cNSgeKlJl3aFtKq3jDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUDGSxO2iv
# q6OB8lgvIc9x9s05C5MwDQYJKoZIhvcNAQEBBQAEgYAIPjIg8toqZJHiP+P9n+IA
# I2enMFxYUwQifMP8PHwPdrkSG2kZlU3NiqVbbnXeEMnwdNVxLdv93tpnOqFN0Wrk
# mXq8flFKPc9hViZv4w8U3LLdxOfckvWLf9cgGT090V29XDbIv3qKJSbkrZ7wo4t+
# zSD8QRM0HymFTlGBV2wa6A==
# SIG # End signature block
