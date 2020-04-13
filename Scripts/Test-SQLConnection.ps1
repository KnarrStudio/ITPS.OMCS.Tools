#requires -Version 3.0
function Test-SQLConnection
{
  <#
      .SYNOPSIS
      Describe purpose of "Test-SQLConnection" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER ConnectionString
      Describe parameter -ConnectionString.

      .EXAMPLE
      Test-SQLConnection -ConnectionString Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Test-SQLConnection

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.

  #>

    
  #[OutputType([bool])]
  Param
  (
    [Parameter(Mandatory,HelpMessage = 'Add SQL ServerNAme',
    ValueFromPipelineByPropertyName,Position = 0)]
    [String]$ConnectionString,
    [Parameter (ParameterSetName = 'Log')]
    [Switch]$Log,
    [Parameter (ParameterSetName = 'Log')]
    [String]$ReportFolder = 'c:\temp\Reports\SqlConnection'
  )
  $ReportFile = (('{0}\FiberSatellite.log' -f $ReportFolder))
  function Write-Log
  {
    param
    (
      $ReportFile,
      $ConnectionString,
      $ReportList,
      $ReportFolder
    )
    $TimeStamp = Get-Date -Format G 
  

    If(-not (Test-Path -Path $ReportFolder))
    {
      $null = New-Item -Path $ReportFolder -ItemType Directory
    }
    ('{0} - {1} tested: {2}' -f  $TimeStamp, $env:USERNAME, $ConnectionString) | Out-File -FilePath $ReportFile -Append
    $ReportList | Out-File -FilePath $ReportFile -Append
    ('-' * 30) | Out-File -FilePath $ReportFile -Append
    Write-Output -InputObject ('You can find the full report at: {0}' -f $ReportFile)
  }
  

  try
  {
    $sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $ConnectionString

    $sqlConnection.Open()

    $sqlConnection.Close()

    If($Log)
    {
      Write-Log   $ReportList = $true
      #return $true
    }
  }
  catch
  {
    If($Log)
    {
      $ReportList = $false
      #return $false
    }
  }
}

# Test-SQLConnection -ConnectionString testserver -Log