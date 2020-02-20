#requires -Version 3.0 -Modules NetTCPIP
function Test-FiberSatellite
{
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

      .PARAMETER Log
      Sends the output to a log file.

      .PARAMETER ReportFolder
      The folder where the output log will be sent.

      .EXAMPLE
      Test-FiberSatellite -Sites Value
    
      .EXAMPLE
      Test-FiberSatellite -Simple
      Creates a simple output

      .EXAMPLE
      Test-FiberSatellite -Log -ReportFolder Value
      Sends the log to the folder identified.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Test-FiberSatellite

      .INPUTS
      List of input types that are accepted by this function.

      .LINK
      https://github.com/KnarrStudio/ITPS-Tools/wiki

      .OUTPUTS
      To console or screen at this time.
  #>

  <#PSScriptInfo

      .VERSION 2.1

      .GUID ac39aa3a-ea05-433f-af82-21925b2af50b

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Test Console NonAdmin User

      .LICENSEURI

      .PROJECTURI  https://github.com/KnarrStudio/ITPS-Tools/wiki

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES Test-NetConnection

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES


      .PRIVATEDATA

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
    [Parameter (ParameterSetName = 'Log')]
    [String]$ReportFolder = "$env:temp\Reports\FiberSatellite"
  )
  
  $ReportList = [Collections.ArrayList]@()
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
      
      $OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $PingReply.Computername, $RTT)
      Write-Verbose  -Message $OutputMessage
      $ReportList += $OutputMessage
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
    Write-Output -InputObject $OutputTable.Report
  }

  if((-not $Simple) -and (-not $Log))
  {
    Write-Output -InputObject $OutputTable.Title 
    if($RTT -gt 380)
    {
      Write-Host -Object ('  ') -BackgroundColor Red -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Red)
    }
    ElseIf($RTT -gt 90)
    {
      Write-Host -Object ('  ') -BackgroundColor Yellow -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Yellow)
    }
    ElseIf($RTT -gt 1)
    {
      Write-Host -Object ('  ') -BackgroundColor Green -ForegroundColor White -NoNewline
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
      New-Item -Path $ReportFolder -ItemType Directory
    }
    $OutputTable.Report | Out-File -FilePath $ReportFile -Append
    $ReportList | Out-File -FilePath $ReportFile -Append
    ('-' * 30) | Out-File -FilePath $ReportFile -Append
    Write-Output -InputObject ('You can find the full report at: {0}' -f $ReportFile)
    Start-Process -FilePath notepad -ArgumentList $ReportFile
  }
}



# For Testing:
#Test-FiberSatellite
#Test-FiberSatellite -Sites localhost,'yahoo.com'
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple 
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple -Verbose
#Test-FiberSatellite -Log -ReportFolder C:\Temp
#Test-FiberSatellite -Log -Verbose




# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUosLCnPROISOz3fSiIutFLdqu
# DKagggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUTmsVK4rd
# 367SGscB8bGcAXvWpX0wDQYJKoZIhvcNAQEBBQAEgYAkGcyKEXcfDg5RPpystg7Y
# d6G7Gx+DRAt30QnNQAtKfu8RNFeuUlhaSGwQjHvs/ykslBGNhBqhFT0vTH5eFBT9
# 3QF9WzcFR4B5w2G/XZSo9vKyrmfhxjpubnLBS7g8Aa2xF9PxCAAkUZ9+8iGDM3VL
# GSgC01zigZ+K4g8U7zjIIw==
# SIG # End signature block
