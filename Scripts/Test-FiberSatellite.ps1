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
    [String[]] $Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Parameter (ParameterSetName = 'Default')]
    [Switch]$Simple,
    [Parameter (ParameterSetName = 'Log')]
    [Switch]$Log,
    [Parameter (ParameterSetName = 'Log')]
    [String]$ReportFile = "$env:SystemDrive\temp\Reports\FiberSatellite\FiberSatellite.log",
    [Parameter(Mandatory,HelpMessage='CSV file that is used for trending')]
    [String]$ReportCsv
    
  )
  
  If(-not (Test-Path -Path $ReportFile))
  {
    $null = New-Item -Path $ReportFile -ItemType File -Force
  }
      
  
  $TimeStamp = Get-Date -Format G 
  $ReportList = [Collections.ArrayList]@()
  $null = @()
  
  $RttTotal = $NotRight = 0
  $TotalResponses = $TotalSites = $Sites.Count
  
  $PingReportInput = Import-Csv -Path $ReportCsv
  $ColumnNames = ($PingReportInput[0].psobject.Properties).name
  
  $OutputTable = @{
    Title  = "`nThe Ping-O-Matic Fiber Tester!"
    Green  = ' Round Trip Time is GOOD!'
    Yellow = ' Although not always the case this could indicate that you are on the backup fiber.'
    Red    = ' Although not always the case this could indicate that you are on the Satellite.'
    Report = ''
  }
  
  $PingStat = [Ordered]@{
    'DateStamp' = $TimeStamp
  }
 
  # Add any new sites to the report file
  foreach($site in $Sites)
  {
    Write-Verbose -Message ('1. {0}' -f $site)
    if(! $ColumnNames.contains($site))
    {
      Write-Verbose -Message ('2. {0}' -f $site)
      $PingReportInput | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
      $PingReportInput  | Export-Csv -Path $ReportFile -NoTypeInformation
    }
  }

  ForEach ($site in $Sites)  
  {
    $PingReply = Test-NetConnection -ComputerName $site 
    if($PingReply.PingSucceeded -eq $true)
    {
      $RTT = $PingReply.PingReplyDetails.RoundtripTime
      $RttTotal += $RTT

      
      if($RTT -eq 0)
      {
        $TotalResponses = $TotalResponses - 1
        $NotRight ++
      }
      
      $OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $PingReply.Computername, $RTT)
      Write-Verbose  -Message $OutputMessage
      $ReportList += $OutputMessage
    }
    Else
    {
      $TotalResponses = $TotalResponses - 1
    }
    
    $PingStat[$site] = [string]$RTT
  }

  $RTT = $RttTotal/$TotalResponses
  #$TimeStamp = Get-Date -Format G 

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
    $OutputTable.Report | Out-File -FilePath $ReportFile -Append
    $ReportList | Out-File -FilePath $ReportFile -Append
    ('-' * 30) | Out-File -FilePath $ReportFile -Append
    Write-Output -InputObject ('You can find the full report at: {0}' -f $ReportFile)
    Start-Process -FilePath notepad -ArgumentList $ReportFile
    
    # Export the hashtable to the file
    $PingStat |
    ForEach-Object -Process {
      [pscustomobject]$_
    } |     
    Export-Csv -Path $ReportCsv -NoTypeInformation -Force -Append
  }
}


$DailySplat = @{
  'Log'     = $true
  'ReportCsv' = 'c:\temp\Reports\Ping.csv'
  'Sites'   = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com')
  'Verbose' = $true
}

Test-FiberSatellite @DailySplat
  

# For Testing:
#Test-FiberSatellite
#Test-FiberSatellite -Sites localhost,'yahoo.com'
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple 
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple -Verbose
#Test-FiberSatellite -Log -ReportFolder C:\Temp
#Test-FiberSatellite -Log -Verbose




