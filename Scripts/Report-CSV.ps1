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
    [Object]
    $InputObject,
    [Parameter(Mandatory = $false, Position = 1)]
    $ReportName
  )
  #$null = $CsvReportFilename.Replace('.csv',('-{0}.csv' -f (Get-Date -Format yyyy)) )
  
  # Set Variables
  Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ),'$HashTable1, $ArrayList1') 
  $HashTable1 = [Ordered]@{
    'DateStamp' = ''
  }
  $ArrayList1 = [Collections.ArrayList]@()
  # Checking for current file  
  if($ReportName -and (Test-Path -Path $ReportName) )
  {
    # Trending CSV file setup and site addition
    Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ),'$ImportedData')
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
    Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 1 ),'$ReportName') 
  }
  # Write Data to HashTable1
  Write-Verbose  -Message ('{0} {1}' -f $(Get-CurrentLineNumber -MsgNum 7 ),'$HashTable1') 
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
}



# Testing Below
$r = Ping-Function -Sites 'yahoo.com','bing.com','google.com','amazon.com','cnn.com' 

$SplatCsvReport = @{
  InputObject = $Pingresult
  ReportName  = "$env:HOMEDRIVE\Temp\Reports\FiberSatellite\ReportCsvFunction2.csv"
  Verbose = $true
}

Write-CsvReport @SplatCsvReport

