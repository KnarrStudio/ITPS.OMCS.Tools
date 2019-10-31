#requires -Version 3.0
function Test-AdWorkstationConnections
{

  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
  param(

    [Parameter(Mandatory=$false, Position=1)]
    [String]
    $ADSearchBase = 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net',
    
    [Parameter(Mandatory=$false, Position=0)]
    [String]
    $PingReportFolder = '\\server\share\Reports\PingReport',

        [Parameter(Mandatory=$false, Position=2)]
    [string]
    $OutputFileName = 'AdDesktop',
    
       [Switch]$Bombastic
  )
  
  $i = 1
  $BadCount = 0
  $DateNow = Get-Date -UFormat %Y%m%d-%H%M
  $OutputFileName = ('{0}\{1}-{2}_Results.csv' -f $PingReportFolder, $DateNow,$OutputFileName)
  $WorkstationSiteList = ('{0}\{1}-{2}_List.csv' -f $PingReportFolder, $DateNow,$OutputFileName)
  

  if(!(Test-Path -Path $PingReportFolder))
  {
    New-Item -Path $PingReportFolder -ItemType Directory
  }
  
  Get-ADComputer -filter * -SearchBase $ADSearchBase -Properties * |
  Select-Object -Property Name, LastLogonDate, Description |
  Sort-Object -Property LastLogonDate -Descending |
  Export-Csv -Path $WorkstationSiteList -NoTypeInformation
  
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
            $WorkstationProperties | Export-Csv -Path $OutputFileName -NoClobber -NoTypeInformation
          }
          else
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileName -NoTypeInformation -Append
          }
        }
      }
    }
  }
  
  if ($Bombastic)
  {
    Write-Host ('Total workstations found in AD: {0}' -f $TotalWorkstations) -ForegroundColor Green
    Write-Host ('Total workstations not responding: {0}' -f $BadCount) -ForegroundColor Red
    Write-Host "This test was run by $env:USERNAME from $env:COMPUTERNAME"
    Write-Host ('You can find the full report at: {0}' -f $OutputFileName)
  }
}
# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYZ19OOIk7hfpaJY+mW3wRlLK
# VTygggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUT2ORSbhK9sK0nvFYt8c0lqv85eww
# DQYJKoZIhvcNAQEBBQAEgYBXDRBI8BOGaeDAQnoC0wUa/0ZfA9BIys9hRTZHyHiS
# VErzjkW0GGPHPMmWFQ2S429CaFz06W6SbRzRzQEKPM/ootNTyGU0/dqztcHs47V+
# kWI+ITNyi32vCR3J5PLYqMfu94UpPiuGFlHxQYqJJ9FzsBhu39BrfEwGVg8T9cjR
# jQ==
# SIG # End signature block
