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
    $ReportName = 'C:\temp\Reports\FiberSatellite\FiberSatellite.log'
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
    Write-Verbose -Message "Site = $site"
    #region Math
    $TotalRtt += ($site.responseTime)
    if($site.PingResult -eq 'Success')
    {
      $TotalResponses ++
    }
    #endregion Math       
    ('{0,-3} ..... {1}' -f $site.ResponseTime, $site.Site) | Tee-Object -FilePath $ReportFile -Append
  }
  
  # Calculate Average RTT
  $AverageRTT = $TotalRtt/$InputObjectcount
  Write-Verbose -Message "Average Rtt = $AverageRTT"
 
  # Create the Report bottomlines
  $OutputTable.Report = (@'

{0,-3} ..... Average Response Time. 
{1} tested {2} remote sites and {3} responded. 
You can find the full report at: {4}
 
 {5}

'@ -f $AverageRTT, $env:USERNAME, $InputObjectcount, $TotalResponses, $ReportFile, ('-' * 30))

  #Write-Verbose -Message $OutputTable.Report
  $OutputTable.Report  | Tee-Object -FilePath $ReportFile -Append

  #| Out-File -FilePath $ReportFile -Append
  # Start-Process -FilePath notepad -ArgumentList $ReportFile
}

#Testing Below
Write-ReportLog -InputObject $Pingresult 
