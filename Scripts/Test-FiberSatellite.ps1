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

      .VERSION 3.0

      .GUID abfd36ca-c464-44d6-a92d-4a01c2078c74

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Test Console NonAdmin User

      .LICENSEURI

      .PROJECTURI  https://github.com/KnarrStudio/ITPS.OMCS.Tools/wiki/Test-FiberSatellite

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
    [Parameter(Mandatory,HelpMessage = 'CSV file that is used for trending',Position = 1,ParameterSetName = 'Log')]
    [String]$ReportCsv

  )
     
  #region Initial Setup
  function Get-CurrentLineNumber 
  {
    $MyInvocation.ScriptLineNumber
  } 

  # Set Variables   
  $TimeStamp = Get-Date -Format G 
  $ReportList = [Collections.ArrayList]@()
  $null = @()
  $RttTotal = $NotRight = 0
  $TotalResponses = $TotalSites = $Sites.Count
 
  $OutputTable = @{
    Title  = "`nThe Ping-O-Matic Fiber Tester!"
    Green  = ' Round Trip Time is GOOD!'
    Yellow = ' The average is a little high.  An email will be generated to send to the Netowrk team to investigate.'
    Red    = ' Although not always the case this could indicate that you are on the Satellite.'
    Report = ''
  }

  $VerboseMsg = @{
    1 = 'Place Holder Message'
    2 = 'Log Switch set'
    3 = 'Test'
  }

  $PingStat = [Ordered]@{
    'DateStamp' = $TimeStamp
  }
  
  # Setup Files
  If(-not (Test-Path -Path $ReportFile))
  {
    $null = New-Item -Path $ReportFile -ItemType File -Force
  }
  #region 'Setup outut CSV File'

  if($ReportCsv) 
  {
    # Trending CSV file setup and site addition
    Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.2)
    $PingReportInput = Import-Csv -Path $ReportCsv
    $ColumnNames = ($PingReportInput[0].psobject.Properties).name

    # Add any new sites to the report file
    foreach($site in $Sites)
    {
      Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.1)
      if(! $ColumnNames.contains($site))
      {
        Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.1)
        $PingReportInput | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
        $PingReportInput  | Export-Csv -Path $ReportFile -NoTypeInformation
      }
    }

  }
    # Log file - with monthly rename

    $OutputTable.Title | Out-File -FilePath $ReportFile -Append
  

  #endregion Initial Setup



  ForEach ($site in $Sites)  
  {
    Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.1)
        
    $PingReply = Test-NetConnection -ComputerName $site 
    
    $RoundTripTime = $PingReply.PingReplyDetails.RoundtripTime
    $PingSucceded = $PingReply.PingSucceeded
    Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.1)
    
    if(($PingSucceded -eq $true) -and ($RoundTripTime -eq 0))
    {
      $PingReply = Test-NetConnection -ComputerName $site 
      $RoundTripTime = $PingReply.PingReplyDetails.RoundtripTime
      $RemoteAddress = $PingReply.RemoteAddress
      $PingSucceded = $PingReply.PingSucceeded
    }
 
    $RttTotal += $RoundTripTime
    Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.1)

    if($PingSucceded -eq $false)
    {
      $TotalResponses = $TotalResponses - 1
      $NotRight ++
    }
      
    $OutputMessage = 'Output Message'
    ('{0} - RoundTripTime is {1} ms.' -f $PingReply.Computername, $RoundTripTime) | Tee-Object -FilePath $ReportFile -Append
    Write-Verbose  -Message $OutputMessage
    $ReportList += $OutputMessage
  }
   
  $PingStat[$site] = [string]$RoundTripTime


  # $RoundTripTime = $RttTotal/$TotalResponses
  #$TimeStamp = Get-Date -Format G 

  $OutputTable.Report = ('{1} - {3} tested {0} remote sites and {2} responded. The average response time: {4}ms' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME, [int]$RoundTripTime) 
 
  Write-Verbose -Message $OutputTable.Report
  #$OutputTable.Report | Out-File $ReportFile
  
  If(-Not $Log)
  {
    Write-Output -InputObject $OutputTable.Report
  }

  if((-not $Simple) -and (-not $Log))
  {
    Write-Output -InputObject $OutputTable.Title 
    if($RoundTripTime -gt 380)
    {
      Write-Host -Object ('  ') -BackgroundColor Red -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Red)
    }
    ElseIf($RoundTripTime -gt 90)
    {
      Write-Host -Object ('  ') -BackgroundColor Yellow -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Yellow)
    }
    ElseIf($RoundTripTime -gt 1)
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
    $LogOutput = (@'

{1}
{0}
 
{2}
{1}
'@ -f $($OutputTable.Report),('-' * 30),('You can find the full report at: {0}' -f $ReportFile))

    $LogOutput | Out-File -FilePath $ReportFile -Append

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
  'Log'      = $true
  'ReportCsv' = "C:\Temp\Reports\FiberSatellite\Ping.csv"
  'Reportfile' = 'C:\temp\Reports\FiberSatellite\Ping.log'
  'Sites'    = ('localhost', 'www.google.com', 'www.bing.com', 'www.yahoo.com')
  'Verbose'  = $true
}

#Test-FiberSatellite @DailySplat
  

# For Testing:
Test-FiberSatellite @DailySplat
#Test-FiberSatellite -Simple
#Test-FiberSatellite -Sites localhost,'yahoo.com'
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple 
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple -Verbose
#Test-FiberSatellite -Log -ReportFolder C:\Temp
#Test-FiberSatellite -Log -Verbose




