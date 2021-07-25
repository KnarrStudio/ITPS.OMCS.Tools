#requires -Version 3.0 -Modules NetTCPIP 

$TestSplat = @{
  'Log'      = $true
  'ReportCsv' = 'C:\Temp\Reports\FiberSatellite\Ping.csv'
  'Reportfile' = 'C:\temp\Reports\FiberSatellite\Ping.log'
  'Sites'    = ('localhost', 'www.google.com', 'www.bing.com', 'www.yahoo.com', 'fooman.shoe', 'asssd')
  'Verbose'  = $true
}

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
      The default values are: ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com')
    
      .EXAMPLE
      Test-FiberSatellite -Simple
      Creates a simple output using the default site list

      .EXAMPLE
      Test-FiberSatellite -Log -ReportFile Value
      Creates a log file with the year and month to create a monthly log.

      .EXAMPLE
      Test-FiberSatellite -Log -ReportCsv Value
      If the file exist is will add the results to that file for trending.  If it doesn't exist, it will create it.

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.Tools/wiki/Test-FiberSatellite

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      To console or screen at this time.
  #>
  <#PSScriptInfo

      .VERSION 4.0

      .GUID 676612d8-4397-451f-b6e3-bc3ae055a8ff

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Test, Console, NonAdmin User

      .LICENSEURI

      .PROJECTURI  https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES NetTCPIP

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
    [ValidateScript({
          If($_ -match '.csv')
          {
            $true
          }
          Else
          {
            Throw 'Input file needs to be CSV'
          }
    })][String]$ReportCsv
  )
  
  #region Initial Setup
  function Get-CurrentLineNumber 
  {
    <#
        .SYNOPSIS
        Get the line number at the command
    #>


    $MyInvocation.ScriptLineNumber
  } 
  
  #region Variables   
  $TimeStamp = Get-Date -Format G 
  $ReportList = [Collections.ArrayList]@()
  $null = @()
  $TotalResponses = $RttTotal = $NotRight = 0
  $TotalSites = $Sites.Count
  $YearMonth = Get-Date -Format yyyy-MMMM
    
  
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
    3 = 'ReportCsv Test'
    4 = 'Column Test'
    5 = 'Region Setup Files'
    6 = 'Create New File'
  }
  
  $PingStat = [Ordered]@{
    'DateStamp' = $TimeStamp
  }
  
  #endregion Variables 
    
  #region Setup Log file
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.5)
  $ReportFile = [String]$($ReportFile.Replace('.',('_{0}.' -f $YearMonth)))
    
  If(-not (Test-Path -Path $ReportFile))
  {
    Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.6)
    $null = New-Item -Path $ReportFile -ItemType File -Force
  }
  
  # Log file - with monthly rename
  $OutputTable.Title | Add-Content -Path $ReportFile 
  ('-'*31) | Add-Content -Path $ReportFile 
  
  #endregion Setup Log file
  
  
  #region Setup Output CSV file
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.5)
  if($ReportCsv) 
  {
    if(Test-Path -Path $ReportCsv)
    {
      # Trending CSV file setup and site addition
      Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.3)
      $PingReportInput = Import-Csv -Path $ReportCsv
      $ColumnNames = ($PingReportInput[0].psobject.Properties).name
      # Add any new sites to the report file
      foreach($site in $Sites)
      {
        Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $site)
        if(! $ColumnNames.contains($site))
        {
          Write-Verbose -Message ('Line {0}:  {1}' -f $(Get-CurrentLineNumber), $VerboseMsg.4)
          $PingReportInput | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
          $PingReportInput  | Export-Csv -Path $ReportCsv -NoTypeInformation
        }
      }
    }
    else
    {
      $null = New-Item -Path $ReportCsv -ItemType File -Force
    }
  }
  #endregion Setup Output CSV file
  
  #endregion Initial Setup
  
  ForEach ($site in $Sites)  
  {
    Write-Verbose -Message ('Line {0}: site: {1}' -f $(Get-CurrentLineNumber), $site)
    $PingReply = Test-NetConnection -ComputerName $site 
    
    $RoundTripTime = $PingReply.PingReplyDetails.RoundtripTime
    $RemoteAddress = $PingReply.RemoteAddress
    $PingSucceded = $PingReply.PingSucceeded
    $RemoteComputerName = $PingReply.Computername

    if($PingSucceded -eq $true)
    {
      $TotalResponses = $TotalResponses + 1
      $RttTotal += $RoundTripTime
      $OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $site, $RoundTripTime)
    
      Write-Verbose -Message ('Line {0}: RttTotal {1}' -f $(Get-CurrentLineNumber), $RttTotal)
    }
    if($PingSucceded -eq $false)
    {
      #$TotalResponses = $TotalResponses - 1
      $NotRight ++
      $OutputMessage = ('{0} - Did not reply' -f $site)
    }
    
    #$OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $site, $RoundTripTime)
    
    $OutputMessage | Add-Content -Path $ReportFile
    
    Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $OutputMessage)
    $ReportList += $OutputMessage
    
    $PingStat[$site] = $RoundTripTime
  }
  
  $RoundTripTime = $RttTotal/$TotalResponses
  $TimeStamp = Get-Date -Format G 
  
  $OutputTable.Report = ('{1} - {3} tested {0} remote sites and {2} responded. The average response time: {4}ms' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME, [int]$RoundTripTime) 
  
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(Get-CurrentLineNumber), $OutputTable.Report)

  #region Console Output
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
  #endregion Console Output
 

  $LogOutput = (
    @'

{0}
{2}
{3}
'@ -f $($OutputTable.Report), ('-' * 31), ('You can find the full report at: {0}' -f $ReportFile), ('=' * 31))

  $LogOutput | Add-Content -Path $ReportFile
    
  Start-Process -FilePath notepad -ArgumentList $ReportFile
    
    
  #region File Output 
  If($Log)
  {
    # Export the hashtable to the file
    $PingStat |
    ForEach-Object -Process {
      [pscustomobject]$_
    } |     
    Export-Csv -Path $ReportCsv -NoTypeInformation -Force -Append
  }
  #endregion File Output 
}


# Test-FiberSatellite @TestSplat


# For Testing:
#Test-FiberSatellite 
#Test-FiberSatellite -Simple
#Test-FiberSatellite -Sites localhost,'yahoo.com'
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple 
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple -Verbose
#Test-FiberSatellite -Log -ReportFolder C:\Temp
#Test-FiberSatellite -Log -Verbose
