#requires -Version 3.0 -Modules PrintManagement
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
# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUM0iMWgrqPUAS9NiXyMzEBTk+
# pqWgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
# MBYxFDASBgNVBAMTC0VyaWtBcm5lc2VuMB4XDTE3MTIyOTA1MDU1NVoXDTM5MTIz
# MTIzNTk1OVowFjEUMBIGA1UEAxMLRXJpa0FybmVzZW4wgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBAKYEBA0nxXibNWtrLb8GZ/mDFF6I7tG4am2hs2Z7NHYcJPwY
# CxCw5v9xTbCiiVcPvpBl7Vr4I2eR/ZF5GN88XzJNAeELbJHJdfcCvhgNLK/F4DFp
# kvf2qUb6l/ayLvpBBg6lcFskhKG1vbEz+uNrg4se8pxecJ24Ln3IrxfR2o+BAgMB
# AAGjYDBeMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEcGA1UdAQRAMD6AEMry1NzZravR
# UsYVhyFVVoyhGDAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlboIQyWSKL3Rtw7JMh5kR
# I2JlijAJBgUrDgMCHQUAA4GBAF9beeNarhSMJBRL5idYsFZCvMNeLpr3n9fjauAC
# CDB6C+V3PQOvHXXxUqYmzZpkOPpu38TCZvBuBUchvqKRmhKARANLQt0gKBo8nf4b
# OXpOjdXnLeI2t8SSFRltmhw8TiZEpZR1lCq9123A3LDFN94g7I7DYxY1Kp5FCBds
# fJ/uMYIBSjCCAUYCAQEwKjAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlbgIQyWSKL3Rt
# w7JMh5kRI2JlijAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUI6aUnExelX4C27EOKGSJwYSez58w
# DQYJKoZIhvcNAQEBBQAEgYCTw7QfOsu65Pvg/mbS/hfdDBstnHSft3IS0hryC3Ce
# g2/R05qLCa9qrfVxTEYfEoBVqr5gMVs8ngX5kVUbgVldBjV5QE1q4APlHIjO7S/i
# Y3ZDh95qouvaCdegbGYFIgrGKbYS51GEJX7m3+IAqlZpreY2ZEVowzW0/LCRP4ip
# cA==
# SIG # End signature block
