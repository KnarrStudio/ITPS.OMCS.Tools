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

    .PARAMETER PingReportFolder
    This is the folder where you want the output to be stored such as  - '\\server\share\Reports\PingReport' or 'c:\temp'

    .PARAMETER OutputFileName
    The name of the file.  Actually base name of the file.  Passing 'AdDesktop' will result in the following file names - '20191112-1851-AdDesktop_List.csv' and '20191112-1851-AdDesktop_Report.csv'

    .PARAMETER Bombastic
    Is a synonym for verose.  It doesn't quite do verbose, but gives you an output to the screen.  Without it you only the the report.  Does you verbose when running as a job. 

    .EXAMPLE
    Test-AdWorkstationConnections -ADSearchBase Value -PingReportFolder Value -OutputFileName Value -Bombastic
    
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
    \\server\share\Reports\PingReport\20191112-1851-AdDesktop_Report.csv
    \\server\share\Reports\PingReport\20191112-1851-AdDesktop_List.csv

    ------------------ Bombasistic Output ----------
    Total workstations found in AD: 32
Total workstations not responding: 5
This test was run by myusername from Workstation-1
You can find the full report at: \\server\share\Reports\PingReport\20191112-1851-AdDesktop_Report.csv

  #>



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
  $OutputFileNameReport = ('{0}\{1}-{2}_Report.csv' -f $PingReportFolder, $DateNow,$OutputFileName)
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
    Write-Host ('Total workstations found in AD: {0}' -f $TotalWorkstations) -ForegroundColor Green
    Write-Host ('Total workstations not responding: {0}' -f $BadCount) -ForegroundColor Red
    Write-Host "This test was run by $env:USERNAME from $env:COMPUTERNAME"
    Write-Host ('You can find the full report at: {0}' -f $OutputFileNameReport)
  }
}
# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYv/GZfIigXgRfHXMJyw9J8e7
# TPagggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUFCwdc/8oGBNA9EPoc8+gaAaiIVQw
# DQYJKoZIhvcNAQEBBQAEgYCh0V91UK+eqNA70P+W4hxhlpcFoWP6d8jul1VO2Zp1
# oD0sjoqm7mKXnCXjpHgjuIg0HPMIXjr3HRJ3fdvIEEyYBJEJvU5+TJsJbm7IxGks
# PNEXZ7dorxbnAW7Q8BBj8irhk5LprvfnzZaIsFtekK1l5A8lxSlMCAViMSbkean6
# rA==
# SIG # End signature block
