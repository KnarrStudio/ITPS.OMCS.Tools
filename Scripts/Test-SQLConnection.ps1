#requires -Version 3.0

function Write-Report 
{
  param
  (
    [Parameter(Position = 0)][String]$TestName = 'ReportDefault',
    [Parameter(Position = 1)][object]$ReportOutput = 'No Output',
    [Parameter(Position = 2)][String]$ReportFolder = "$env:HOMEDRIVE\temp\WriteReport",
    [Parameter(Position = 3)][String]$ReportFile = 'ReportFile.txt'
  )

  $TimeStamp = Get-Date -Format G 
  $ReportPath = ('{0}\{1}' -f $ReportFolder, $ReportFile)
 
  If(-not (Test-Path -Path $ReportPath)) 
  {
    If(-not (Test-Path -Path $ReportFolder)) 
    {
      $null = New-Item -Path $ReportFolder -ItemType Directory
    }
    If(-not (Test-Path -Path $ReportPath)) 
    {
      $null = New-Item -Path $ReportPath -ItemType File
    }
  }

  ('{0} - {1} tested {2} from {3}' -f $TimeStamp, $env:USERNAME, $TestName, $env:COMPUTERNAME) | Out-File -FilePath $ReportPath -Append
  $ReportOutput | Out-File -FilePath $ReportPath -Append
  ('-' * 30) | Out-File -FilePath $ReportPath -Append
  Write-Output -InputObject ('You can find the full report at: {0}' -f $ReportPath)
}
 
function Test-SQLConnection
{ 
  [OutputType([bool])]
  Param
  (
    [Parameter(Mandatory,HelpMessage = 'Add SQL ServerName',
    ValueFromPipelineByPropertyName,Position = 0)]
    [String]$ConnectionString
  )
 
  try
  {
    $sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $ConnectionString
    $sqlConnection.Open()
    $sqlConnection.Close()
    return $true
  }
  catch
  {
    return $false
  }
}

$ReportOutput = [Collections.ArrayList]@()
$ReportOutput += 'testserver'
$ReportOutput += Test-SQLConnection -ConnectionString testserver

Write-Report -TestName TestSqlConnection -ReportOutput $ReportOutput -ReportFolder 'C:\temp\Reports\TestSqlConnection' -ReportFile SqlConnection.txt
 
$ReportOutput