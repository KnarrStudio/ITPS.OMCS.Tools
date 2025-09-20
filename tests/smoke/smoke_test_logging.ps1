try {
    Import-Module ..\..\Modules\LoggingModule.psm1 -Force

    Write-Output '=== Module Functions ==='
    Get-Command -Module LoggingModule | Select-Object Name,CommandType | Format-Table -AutoSize

    $tf = New-TimeStampFile -baseNAME 'SmokeTest' -ReportFolder $env:TEMP
    Write-Output "New-TimeStampFile created: $tf"
    Write-Output "New-TimeStampFile exists: $(Test-Path $tf)"

    $csv = Join-Path $env:TEMP 'SmokeTest-Report.csv'
    $data = @([pscustomobject]@{Site='example.com'; ResponseTime=123; DateStamp=(Get-Date -Format yyyyMMdd)})
    $data | Write-CsvReport -Path $csv -Append
    Write-Output "CSV exists: $(Test-Path $csv)"
    if (Test-Path $csv) { Write-Output 'CSV head:'; Get-Content $csv -TotalCount 10 }

    $log = Join-Path $env:TEMP 'SmokeTest.log'
    $sample = @([pscustomobject]@{Site='example.com'; ResponseTime=99; PingResult='Success'})
    $report = Write-ReportLog -InputObject $sample -ReportName $log
    Write-Output "Report log created: $report"
    Write-Output 'Log head:'
    if (Test-Path $report) { Get-Content $report -TotalCount 20 } else { Write-Output 'Report file not found.' }

    exit 0
}
catch {
    Write-Error $_
    exit 1
}
