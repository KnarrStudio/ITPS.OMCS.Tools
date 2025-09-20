function New-TimeStampFile
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory,HelpMessage='Prefix of file or log name')]
    [String]$baseNAME,
    [Parameter(Mandatory=$false,HelpMessage='Extension of file. txt, csv, log')]
    [alias('Extension')]
    [String]$FileType = 'log',
    [Parameter(Mandatory,HelpMessage='Formatting Choice 1 to 4')]
    [ValidateRange(1,4)]
    [int]$StampFormat = 2,
    [Parameter(ValueFromPipeline,HelpMessage='Folder Path')]
    [AllowNull()]
    [String]$ReportFolder
  )

  switch ($StampFormat){
    1 { $DateStamp = Get-Date -UFormat '%y%m%d%H%M' }
    2 { $DateStamp = Get-Date -UFormat '%Y%m%d' }
    3 { $DateStamp = Get-Date -UFormat '%j%H%M%S' }
    4 { $DateStamp = Get-Date -Format o | ForEach-Object {$_ -replace ':', '.'} }
    default { Write-Verbose 'No time format selected'; return }
  }

  $FileName = ('{0}-{1}.{2}' -f $baseNAME, $DateStamp, $FileType)

  if ($ReportFolder) {
    if (-not (Test-Path -Path $ReportFolder)) { New-Item -Path $ReportFolder -ItemType Directory -Force | Out-Null }
    $FullPath = Join-Path -Path $ReportFolder -ChildPath $FileName
    New-Item -Path $FullPath -ItemType File -Force | Out-Null
    return $FullPath
  }
  else { return $FileName }
}

function Write-CsvReport
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [Object[]]$InputObject,
    [Parameter(Mandatory)]
    [String]$Path,
    [Parameter()]
    [Switch]$Append
  )

  Begin {
    $mode = if ($Append) {'-Append'} else {'-Force'}
  }
  Process {
    if ($Append -and (Test-Path -Path $Path)) {
      $InputObject | Export-Csv -Path $Path -NoTypeInformation -Append
    }
    else {
      $InputObject | Export-Csv -Path $Path -NoTypeInformation -Force
    }
  }
}

function Write-ReportLog
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true,Position=0)] [object]$InputObject,
    [Parameter(Position=1)] [String]$ReportName = 'C:\temp\Reports\FiberSatellite\FiberSatellite.log'
  )

  $InputObjectcount = $InputObject.count
  $TimeStamp = Get-Date -Format G
  $DateStamp = Get-Date -Format yyyy-MMM
  [String]$ReportFile = $ReportName.Replace('.log', ('_{0}.log' -f $DateStamp))

  $OutputTable = @{
    Title     = "`nThe Ping-O-Matic Fiber Tester!"
    TimeStamp = $TimeStamp
    Green     = ' Round Trip Time is GOOD!'
    Yellow    = ' The average is a little high.  An email will be generated to send to the Network team to investigate.'
    Red       = ' Although not always the case this could indicate that you are on the Satellite.'
    Report    = ''
  }

  if (-not (Test-Path -Path $ReportFile)) {
    New-Item -Path $ReportFile -ItemType File -Force | Out-Null
    $OutputTable.Title | Out-File -FilePath $ReportFile -Append
  }

  $OutputTable.TimeStamp | Out-File -FilePath $ReportFile -Append

  $TotalRtt = 0; $TotalResponses = 0
  foreach ($site in $InputObject) {
    $TotalRtt += ($site.responseTime)
    if ($site.PingResult -eq 'Success') { $TotalResponses++ }
    ('{0,-3} ..... {1}' -f $site.ResponseTime, $site.Site) | Tee-Object -FilePath $ReportFile -Append | Out-Null
  }

  $AverageRTT = if ($InputObjectcount -gt 0) { $TotalRtt / $InputObjectcount } else { 0 }

  $OutputTable.Report = (@'

{0,-3} ..... Average Response Time. 
{1} tested {2} remote sites and {3} responded. 
You can find the full report at: {4}
 
 {5}

'@ -f $AverageRTT, $env:USERNAME, $InputObjectcount, $TotalResponses, $ReportFile, ('-' * 30))

  $OutputTable.Report | Tee-Object -FilePath $ReportFile -Append | Out-Null
  return $ReportFile
}

Export-ModuleMember -Function New-TimeStampFile, Write-CsvReport, Write-ReportLog

function New-TimeStampFileName
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory,HelpMessage='Prefix of file or log name')]
    [String]$baseNAME,
    [Parameter(Mandatory=$false,HelpMessage='Extension of file. txt, csv, log')]
    [alias('Extension')]
    [String]$FileType = 'log',
    [Parameter(Mandatory,HelpMessage='Formatting Choice 1 to 4')]
    [ValidateRange(1,4)]
    [int]$StampFormat = 2,
    [Parameter(ValueFromPipeline,HelpMessage='Folder Path')]
    [AllowNull()]
    [String]$ReportFolder
  )

  return New-TimeStampFile -baseNAME $baseNAME -FileType $FileType -StampFormat $StampFormat -ReportFolder $ReportFolder
}

Export-ModuleMember -Function New-TimeStampFile, New-TimeStampFileName, Write-CsvReport, Write-ReportLog
