#requires -Version 3.0

$SplatFiberSatellite = @{
  LogFileName = "$env:SystemDrive\temp\Reports\FiberSatellite\FiberSatellite.log"
  CsvFileName = "$env:HOMEDRIVE\Temp\Reports\FiberSatellite\ReportCsvFunction2.csv"
  Sites       = ('localhost', 'www.google.com', 'www.bing.com', 'mouse.house', 'www.wolframalpha.com', 'www.yahoo.com', 'www.wikipedia.org')
  Verbose     = $false
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

  #>
   
  [cmdletbinding(DefaultParameterSetName = 'Default')]
  param
  (
    [Parameter(Position = 0)]
    [String[]] $Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Parameter (Mandatory ,Position = 1)]
    [String]$LogFileName,
    [Parameter(Mandatory ,Position = 2)]
    [String]$CsvFileName
  )
  
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
    
  
  function Get-CurrentLineNumber
  {
    <#
        .EXAMPLE
        Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ),'') 
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

  Function Ping-Function
  {
    <#
        .SYNOPSIS
        Does the Ping work. This should hopefully be modular enough to take to the other "Ping scripts"
    #>
    param
    (
      [Parameter(Position = 0)]
      [String[]] $Sites
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
        if($site.PrimaryAddressResolutionStatus  -ne 0)
        {
          $TotalResponses = $TotalResponses - 1
          $NotRight = $NotRight + 1
          Write-Verbose -Message ('Responses: {0} - Not Right {1} - Address Resolution {2}' -f $TotalResponses, $NotRight, $site.PrimaryAddressResolutionStatus)
        }
      
        Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ), '$PingHTList') 
        $PingHTList.DateStamp = [String]$TimeStamp
        $PingHTList.Site = [String]$site.Address
        $PingHTList.IpAddress = [String]$site.IPV4Address  
        $PingHTList.ResponseTime = [String]$site.ResponseTime
        $PingHTList.PingResult = (Show-PingStatus -InputObject ($site.PrimaryAddressResolutionStatus))
      
        Write-Verbose -Message ('{0} - {1} - {2}' -f $site.Address, $site.ResponseTime, $site.PrimaryAddressResolutionStatus)
      
        # Converts the hash table to object
        Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ), '$PingHTList') 
        $null = $ReportList.Add([pscustomobject]$PingHTList)
      } # End ForEach
    } # End Process
    End {
      $ReportList
    }
  }

  function Write-CsvReport
  {
    <#
        .SYNOPSIS
        Short Description
    #>
    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Output from the "Ping Function"')]
      [Object]$InputObject,
      [Parameter(Mandatory = $true, Position = 1)]
      [Object]$ReportName,
      [Parameter(Mandatory = $false, Position = 2)]
      [Switch]$ShowPath
    )
    #$null = $CsvReportFilename.Replace('.csv',('-{0}.csv' -f (Get-Date -Format yyyy)) )
  
    # Set Variables
    Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ), '$HashTable1, $ArrayList1') 
    $HashTable1 = [Ordered]@{
      'DateStamp' = ''
    }
    $ArrayList1 = [Collections.ArrayList]@()
    # Checking for current file  
    if($ReportName -and (Test-Path -Path $ReportName) )
    {
      # Trending CSV file setup and site addition
      Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ), '$ImportedData')
      $ImportedData = Import-Csv -Path $ReportName
      $ColumnNames = ($ImportedData[0].psobject.Properties).name
      # Add any new sites to the report file
      foreach($site in $InputObject.site)
      {
        Write-Verbose  -Message ('{0}' -f $(Get-CurrentLineNumber -MsgNum 5 )) 
        if(-not $ColumnNames.contains($site))
        {
          Write-Verbose  -Message ('{0}' -f $(Get-CurrentLineNumber -MsgNum 7 )) 
          $ImportedData | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
          $ImportedData  | Export-Csv -Path $ReportName -NoTypeInformation
        }
      }
    }
    else
    {
      New-Item -Path $ReportName -ItemType File -Force
      Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ), '$ReportName') 
    }
    # Write Data to HashTable1
    Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ), '$HashTable1') 
    $HashTable1.DateStamp = $InputObject[0].DateStamp
    $InputObject | ForEach-Object -Process {
      $HashTable1[($_.Site)] = $_.ResponseTime
    }
    # Converts the hash table to Custom PS object so that it can "Export-CSV"
    Write-Verbose  -Message ('{0}' -f $(Get-CurrentLineNumber -MsgNum 1 )) 
    $null = $ArrayList1.Add([pscustomobject]$HashTable1)
    # Write "Export" to the CSV file
    Write-Verbose  -Message ('{0}' -f $(Get-CurrentLineNumber -MsgNum 1 )) 
    $ArrayList1  |     Export-Csv -Path $ReportName -NoTypeInformation -Force -Append
    
    if($ShowPath){Write-Output ('You can find the CSV report at: {0}' -f $ReportName)}
  }


  function Write-ReportLog
  {
    <#
        .SYNOPSIS
        Short Description
    #>
    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Output from the "Ping Function"')]
      [Object]
      $InputObject,
      [Parameter(Mandatory = $false, Position = 1)]
      [string]$ReportName
    )
  
    # Set Variables
    $AverageRTT = $TotalRtt = $TotalResponses = 0
    $InputObjectcount = $InputObject.count
    $TimeStamp = Get-Date -Format G
    $DateStamp = Get-Date -Format yyyy-MMM
    [String]$ReportFile = $ReportName.Replace('.log',('_{0}.log' -f $DateStamp))
  
  
    $OutputTable = @{
      Title     = "`nThe Ping-O-Matic Fiber Tester!"
      TimeStamp = $TimeStamp
      Green     = ' Round Trip Time is GOOD!'
      Yellow    = ' The average is a little high.  An email will be generated to send to the Netowrk team to investigate.'
      Red       = ' Although not always the case this could indicate that you are on the Satellite.'
      Report    = ''
    }
  
    # Checking for current file  
    if(-not(Test-Path -Path $ReportFile))
    {
      # Log file - with monthly rename
      Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ), '$ReportFile')
      $null = New-Item -Path $ReportFile -ItemType File -Force
      $OutputTable.Title | Out-File -FilePath $ReportFile -Append
    }  
  
    # Write to log file 
    $OutputTable.TimeStamp | Out-File -FilePath $ReportFile -Append
    Foreach($site in $InputObject)
    {
      Write-Verbose -Message ('Site = {0}' -f $site)
      #region Math
      $TotalRtt += ($site.responseTime)
      if($site.PingResult -eq 'Success')
      {
        $TotalResponses ++
      }
      #endregion Math       
      ('{0,3} ..... {1}' -f $site.ResponseTime, $site.Site) | Tee-Object -FilePath $ReportFile -Append
    }
  
    # Calculate Average RTT
    $AverageRTT = $TotalRtt/$InputObjectcount
    Write-Verbose -Message ('Average Rtt = {0}' -f $AverageRTT)
 
    # Create the Report bottomlines
    $OutputTable.Report = ('{0,3:n2} ..... Average Response Time.' -f $AverageRTT)
    $OutputTable.Report += (@'
{1} tested {2} remote sites and {3} responded. 
You can find the monthly log report at: {4}
 {5}

'@ -f $AverageRTT, $env:USERNAME, $InputObjectcount, $TotalResponses, $ReportFile, ('-' * 30))

    #Write-Verbose -Message $OutputTable.Report
    $OutputTable.Report  | Tee-Object -FilePath $ReportFile -Append

    #| Out-File -FilePath $ReportFile -Append
    # Start-Process -FilePath notepad -ArgumentList $ReportFile
  }
  
  # Runs the Functions here
  $Pingresult = Ping-Function -Sites $Sites 

  $SplatLogReport = @{
    InputObject = $Pingresult
    ReportName  = $LogFileName
  }
   
  $SplatCsvReport = @{
    InputObject = $Pingresult
    ReportName  = $CsvFileName
    ShowPath = $true
  }

  Write-ReportLog @SplatLogReport 
  Write-CsvReport @SplatCsvReport
}



# Start Script 
Test-FiberSatellite @SplatFiberSatellite

