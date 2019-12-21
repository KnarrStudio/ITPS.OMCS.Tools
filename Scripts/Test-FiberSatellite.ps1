#requires -Version 3.0 -Modules NetTCPIP
function Test-FiberSatellite
{
  <#PSScriptInfo

      .VERSION 2.0

      .GUID c528ef9f-ccdf-47ca-8885-8883598c5e79

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Test Console NonAdmin User

      .LICENSEURI

      .PROJECTURI

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES Test-NetConnection

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES


      .PRIVATEDATA

  #>
  <# 

      .SYNOPSIS
      "Pings" a group of sites or servers and gives a response in laymans terms.

      .DESCRIPTION 
      "Pings" a group of sites or servers and gives a response in laymans terms. 
      This started due to our need to find out if transport was over fiber or bird.  
      There are some default remote sites that it will test, but you can pass your own if you only want to check one or two sites. 

      .PARAMETER Sites
      A single or list of sites or servers that you want to test against.

      .PARAMETER Simple
      Provides a single output line for those who just need answers.

      .EXAMPLE
      Test-FiberSatellite -Sites Value -Simple
      Tests the Value and displays the output as a single line of text

      .NOTES
      Place additional notes here.

      .LINK
      https://github.com/KnarrStudio/ITPS-Tools/wiki

      .OUTPUTS
      To console or screen at this time.
  #>

  [cmdletbinding(DefaultParameterSetName = 'Default')]
  param
  (
    [Parameter(Position = 0)]
    [Object[]] $Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Parameter (ParameterSetName = 'Default')]
    [Switch]$Simple,
    [Parameter (ParameterSetName = 'Log')]
    [Switch]$Log,
    [Parameter (Mandatory,HelpMessage = 'C:\Temp\Reports',ParameterSetName = 'Log')]
    [String]$ReportFolder
  )
  
  $RttTotal = $NotRight = 0
  $TotalResponses = $TotalSites = $Sites.Count
  $ReportFile = (('{0}\FiberSatellite.log' -f $ReportFolder))
  
  $OutputTable = @{
    Title  = "`nThe Ping-O-Matic Fiber Tester!"
    Green  = ' Round Trip Time is GOOD!'
    Yellow = ' Although not always the case this could indicate that you are on the backup fiber.'
    Red    = ' Although not always the case this could indicate that you are on the Satellite.'
    Report = ''
  }

  ForEach ($Site in $Sites)  
  {
    $PingReply = Test-NetConnection -ComputerName $Site 
    if($PingReply.PingSucceeded -eq $true)
    {
      $RTT = $PingReply.PingReplyDetails.RoundtripTime
      $RttTotal = $RttTotal + $RTT
    
      if($RTT -eq 0)
      {
        $TotalResponses = $TotalResponses - 1
        $NotRight = $NotRight + 1
      }
      Write-Verbose -Message ('{0} - RoundTripTime is {1} ms.' -f $PingReply.Computername, $RTT)
    }
    Else
    {
      $TotalResponses = $TotalResponses - 1
    }
  }

  $RTT = $RttTotal/$TotalResponses
  $TimeStamp = Get-Date -Format G 

  $OutputTable.Report = ('{1} - {3} tested {0} remote sites and {2} responded. The average response time: {4}ms' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME, [int]$RTT) 
 
  Write-Verbose -Message $OutputTable.Report
  #$OutputTable.Report | Out-File $ReportFile
  
  If(-Not $Log)
  {
    Write-Output -Message $OutputTable.Report
  }

  if((-not $Simple) -and (-not $Log))
  {
    Write-Output $OutputTable.Title 
    if($RTT -gt 380)
    {
      Write-Host('  ') -BackgroundColor Red -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Red)
    }
    ElseIf($RTT -gt 90)
    {
      Write-Host ('  ') -BackgroundColor Yellow -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Yellow)
    }
    ElseIf($RTT -gt 1)
    {
      Write-Host ('  ') -BackgroundColor Green -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Green) 
    }
    if($NotRight -gt 0)
    {
      Write-Output -InputObject ('{0} Responded with 0 ms.  If you tested the "Localhost" one would be expected.' -f $NotRight)
    }
  }
  If($Log)
  {
    If(-not (Test-Path -Path $ReportFolder))
    {
      New-Item -Name $ReportFolder -ItemType Directory
    }
    $OutputTable.Report | Out-File -FilePath $ReportFile -Append
  }
}


# For Testing:
#Test-FiberSatellite



# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxVp5a/ao8nhEJNPc5cZM8Wop
# LwegggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUVGpMMUO814+EqrICQnn5DsfE9+kw
# DQYJKoZIhvcNAQEBBQAEgYAnss4R/Cr49JbYL0ArI03IOPII9hQbIPoXp3aaYhjs
# JqAnyrAmgqnW+7FeMuDpb8kRsQmdHpyfnD4uJDdflagmMfmLbCBUxCzWFUMR10Fv
# gWZvVp1KiOr0RMo4rF2HuZRKppWwIa46hCtRDaiXd8A+bWFigVf68pCpjh6HrDKu
# Vw==
# SIG # End signature block
