#requires -Version 4.0 
function Test-FiberSatellite
{
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
  Begin {  
    #region Initial Setup
    $LineFormatText = 'Line {0}:  {1}'
    function Get-AverageRTT
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    $ReceivedJob
  )
  $r = 0
  (1..$($ReceivedJob.Count)).ForEach({
      $r = $r+($ReceivedJob[$_].ResponseTime)
  })
  $r/$ReceivedJob.Count
}
    
    function Get-PingStatus 
    {
      param([Parameter(Mandatory = $true)]$InputObject)
      switch ($InputObject
      ) {
        0  
        {
          'Success'
        }
        11003  
        {
          'Destination Host Unreachable'
        }
        11050  
        {
          'General Failure'
        }
        Default 
        {
          'Unknown Issue'
        }
      }
    }
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

    #region Setup Files
    If(-not (Test-Path -Path $ReportFile))
    {
      $null = New-Item -Path $ReportFile -ItemType File -Force
    }

    #region CSV File
    if($ReportCsv) 
    {
      # Trending CSV file setup and site addition
      Write-Verbose -Message ($LineFormatText -f $(Get-CurrentLineNumber), $VerboseMsg.2)
      $PingReportInput = Import-Csv -Path $ReportCsv
      $ColumnNames = ($PingReportInput[0].psobject.Properties).name
      # Add any new sites to the report file
      foreach($site in $Sites)
      {
        Write-Verbose -Message ($LineFormatText -f $(Get-CurrentLineNumber), $VerboseMsg.1)
        if(! $ColumnNames.contains($site))
        {
          Write-Verbose -Message ($LineFormatText -f $(Get-CurrentLineNumber), $VerboseMsg.1)
          $PingReportInput | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
          $PingReportInput  | Export-Csv -Path $ReportFile -NoTypeInformation
        }
      }
    }do
     {
           $ReceivedJob = Receive-Job -Job $pingjob -Wait
     }
     until ($x -gt 0)
     
    #endregion CSV File
    # Log file - with monthly rename
    $OutputTable.Title | Add-Content -Path $ReportFile
    #endregion Setup Files
  }
  Process  {
    $OutputMessage = 'Output Message'
    #$ReportList += $OutputMessage   
    $pingjob = Test-Connection -ComputerName $Sites -AsJob -Count 1
    $ReceivedJob = Receive-Job -Job $pingjob -Wait
    ForEach($site in $ReceivedJob)
    {
      if($site.StatusCode -eq 0)
      {
        $TotalResponses = $TotalResponses + 1
        $RttTotal += $site.ResponseTime
      }
      else
      {
        $TotalResponses = $TotalResponses - 1
        $NotRight = $NotRight + 1
      }
    
      $PingSucceded = Get-PingStatus -InputObject ($site.StatusCode)

      '{0} - {1} - {2}' -f $site.Address,$site.ResponseTime,$PingSucceded
      $ReportList += ('{0} - RoundTripTime is {1} ms.' -f $site.Address,$site.ResponseTime) # | Add-Content -Path $ReportFile
 

      Write-Verbose -Message ($LineFormatText -f $(Get-CurrentLineNumber), $VerboseMsg.1)

    } # End ForEach

$AverageRTT = Get-AverageRTT
         $ReportList
  } # End Process
    
  <#

      for($i = 0;$i -lt $Sites.Count;$i++)
      {
      $site = $Sites[$i] 
      #$r[$i].Address
      $RoundTripTime = $ReceivedJob[$i].ResponseTime
      $PingStatusCode = $ReceivedJob[$i].StatusCode
      $PingStat[$site] = [string]$RoundTripTime

      $RttTotal += $RoundTripTime
      

      


      
      }

      $RoundTripTime = $RttTotal/$TotalResponses
      $OutputTable.Report = ('{1} - {3} tested {0} remote sites and {2} responded. The average response time: {4}ms' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME, [int]$RoundTripTime) 
      Write-Verbose -Message $OutputTable.Report
      #$OutputTable.Report | Out-File $ReportFile
    
      If(-Not $Log)
      {
      #Write-Output -InputObject $PingStat
      # Write-Output -InputObject $OutputTable.Report
      }
      # Export the hashtable to the file
      $PingStat |
      ForEach-Object -Process {
      [pscustomobject]$_
      } |     
      Export-Csv -Path $ReportCsv -NoTypeInformation -Force -Append
      $LogOutput = (@'

      {1}
      {0}
      {3}
      {2}
      {1}
      '@ -f $($OutputTable.Report), ('-' * 30), ('You can find the full report at: {0}' -f $ReportFile),$ReportList)
      }
  #>

  End {
  }
}




$DailySplat = @{
  'Log'      = $true
  'ReportCsv' = 'C:\Temp\Reports\FiberSatellite\Ping.csv'
  'Reportfile' = 'C:\temp\Reports\FiberSatellite\Ping.log'
  'Sites'    = ('localhost', 'www.google.com', 'www.bing.com', 'www.yahoo.com')
  'Verbose'  = $true
}
# For Testing:
$ReportList = Test-FiberSatellite @DailySplat
#Test-FiberSatellite -Simple
#Test-FiberSatellite -Sites localhost,'yahoo.com'
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple 
#Test-FiberSatellite -Sites localhost,'yahoo.com' -Simple -Verbose
#Test-FiberSatellite -Log -ReportFolder C:\Temp
#Test-FiberSatellite -Log -Verbose
