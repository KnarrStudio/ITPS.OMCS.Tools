#requires -Version 2.0 -Modules NetTCPIP
function Test-FiberSatellite
{
  <#
      .SYNOPSIS
      "Pings" a group of sites or servers and gives a response in laymans terms.

      .DESCRIPTION
      This started due to our need to find out if we were running on Fiber or not.  There are some default off island sites that it will test, but you can pass them if you only want to check one or two sites.

      .PARAMETER Sites
      A single or list of sites or servers that you want to test against.

      .PARAMETER OneLineOutput
      Provides a single output line for those who just need answers.

      .EXAMPLE
      Test-FiberSatellite -Sites Value -OneLineOutput
      Tests the Value and displays the output as a single line of text

      .NOTES
      Place additional notes here.

      .LINK
      https://github.com/KnarrStudio/ITPS-Tools/wiki

      .OUTPUTS
      To console or screen at this time.
  #>

  param
  (
    [Parameter(Position = 0)]
    [Object[]] $Sites = ('LocalServer', 'localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Switch]$OneLineOutput
  )
  
  $RttTotal = $NotRight = 0
  $TotalResponses = $TotalSites = $Sites.Count
  function Test-Verbose 
  {
    [Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference
  }
    if(-not $OneLineOutput)
    {
    Write-Host ('The Ping-O-Matic Fiber Tester!') -BackgroundColor DarkYellow -ForegroundColor White}
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
  $TimeStamp = Get-Date -Format 'dd-MMM-yyyy HH:mm'
  if(-not $OneLineOutput)
  {
    <#    if(Test-Verbose)
    {#>
    if($RTT -gt 380)
    {
      Write-Host('Although not always the case this could indicate that you are on the Satellite backup circuit.') -BackgroundColor Red -ForegroundColor White
    }
    ElseIf($RTT -gt 90)
    {
      Write-Host ('Although not always the case this could indicate that you are on the Puerto Rico backup circuit.') -BackgroundColor Yellow -ForegroundColor White
    }
    ElseIf($RTT -gt 1)
    {
      Write-Host ('Round Trip Time is GOOD!') -BackgroundColor Green -ForegroundColor White
    }
    # }
  }
  Write-Host ('{1} - {3} tested {0} off island computers and {2} responded. The average response time:' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME) -ForegroundColor DarkYellow -NoNewline
  Write-Output -InputObject (' {0} ms' -f [int]$RTT)

  if($NotRight -gt 0)
  {
    Write-Output -InputObject ('{0} Responded with 0 ms' -f $NotRight)
  }

  <#  Write-Output -InputObject ('Average RTT is {0} ms.' -f [int]$RTT)
      if ($RTT -lt 380){
  Start-Process "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe" }#>
}
# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUksM8M6dNdFxsgRlyGQERqmvt
# 8EWgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUnJsnVBQh3wPndD8xVTtjHoHkFpAw
# DQYJKoZIhvcNAQEBBQAEgYCiuS+mDFc3FY6Hu/0cxWYSh0FbRxWLaGr8WQ4U/Vs5
# wtKFnkSViUUxiNybz9IaG8JA3ixH6SluI4FGZeVwYpMlUzp/GcguWNubZrLU4dXm
# c5WETqqNY/oqP454iMUX+FKWysM/DGfayT8JWZyo6uwsGTg4vagQbGUR0ca8YCJw
# eA==
# SIG # End signature block
