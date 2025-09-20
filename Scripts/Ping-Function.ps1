#requires -Version 3.0
function Get-CurrentLineNumber
{
  <#
      .SYNOPSIS
      A quick way to write where in the code you are

      .EXAMPLE
      Write-Verbose  -Message ('{0}' -f $(Get-CurrentLineNumber -MsgNum 1 ))

      .NOTE
      1 = 'Set Variable'
      2 = 'Set Switch Variable'
      3 = 'Set Path/FileName'
      4 = 'Start Function'
      5 = 'Start Loop'
      6 = 'End Loop'
      7 = 'Write Data'
      99 = 'Current line number'
  #>
  param
  (
    [Parameter(Mandatory,HelpMessage = 'Add help message for user', Position = 0)]
    [int]$MsgNum
  )
  $VerboseMsg = @{
    1 = 'Set Variable'
    2 = 'Set Switch Variable'
    3 = 'Set Path/FileName'
    4 = 'Start Function'
    5 = 'Start Loop'
    6 = 'End Loop'
    7 = 'Write Data'
    99 = 'Current line number'
  }
  if($MsgNum -gt $VerboseMsg.Count)
  {
    $MsgNum = 99
  }#$VerboseMsg.Count}
  'Line {0}:  {1}' -f $MyInvocation.ScriptLineNumber, $($VerboseMsg.$MsgNum)
} 

#   Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ),'') 

Function Ping-Function
{
  <#
      .SYNOPSIS
      Does the Ping work. This should hopefully be modular enough to take to the other "Ping scripts"
  #>
  param
  (
    [Parameter(Position = 0)]
    [String[]] $Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com')
  )
  Begin {
    # Set Variables  
    $RttTotal = $NotRight = 0
    $TotalResponses = $TotalSites = $Sites.Count 
    $TimeStamp = Get-Date -Format G 
    $ReportList = [Collections.ArrayList]@()
    $PingHTList = [Ordered]@{
      'DateStamp' = $TimeStamp
    }
    
    function Get-AverageRTT 
    {
      <#
          .SYNOPSIS
          Returns the average response times by calculating the information in the $ReceivedJob object
      #>
      param
      (
        [Parameter(Mandatory = $true, Position = 0)]
        [Object]$ReceivedJob
      )
      $RttTotal = $null
      ForEach($SiteJob in $ReceivedJob)
      {
        $RttTotal += $SiteJob.ResponseTime
      }
      [float]$RttTotal / $ReceivedJob.Count
    }
    
    function Show-PingStatus 
    {
      <#
          .SYNOPSIS
          Translates the "Status Code" to something meaningful for the user
      #>
      param([Parameter(Mandatory = $true)]
      [int]$InputObject)
      switch ($InputObject)
      {      
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
  } # End Begin
  Process {
    # Starts the actual "Ping Job" here.  
    # Then it will receive the job after waiting for it to be completed.  
    # Removes the jobs from memory
    $pingjob = Test-Connection -ComputerName $Sites -AsJob -Count 1
    $ReceivedJob = Receive-Job -Job $pingjob -Wait
    Remove-Job -Job $pingjob

    # Works on the $ReceivedJob to get the data
    # Adds it to a hash table
    # Converts the hash table to an Object
    ForEach($site in $ReceivedJob)
    {
      if($site.StatusCode -ne 0)
      {
        $TotalResponses = $TotalResponses - 1
        $NotRight = $NotRight + 1
      }
      
      Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ),'$PingHTList') 
      $PingHTList.DateStamp = [String]$TimeStamp
      $PingHTList.Site = [String]$site.Address
      $PingHTList.IpAddress = [String]$site.IPV4Address  
      $PingHTList.ResponseTime = [String]$site.ResponseTime
      $PingHTList.PingResult = (Show-PingStatus -InputObject ($site.StatusCode))
      
      Write-Verbose -Message ('{0} - {1} - {2}' -f $site.Address, $site.ResponseTime, $site.StatusCode)
      
      # Converts the hash table to object
      Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ),'$PingHTList') 
      $null = $ReportList.Add([pscustomobject]$PingHTList)
      
    } # End ForEach
  } # End Process
  End {
    $ReportList
    }
}

#Testing Below
$Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com')
$Pingresult = Ping-Function -Sites $Sites -Verbose
