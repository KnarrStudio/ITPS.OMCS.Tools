#requires -Version 4.0 
<#
    .SYNOPSIS
    Use this to run the daily checks.  

    .DESCRIPTION
    Use this to run the daily checks.  It uses the "MyLocalParameters.txt" file and splat to set the parameters for each of the modules.
    Modify the "MyLocalParameters.txt" file to complete the 

    .EXAMPLE
    Start-DailyChecks

#>

param
(
  [Parameter(Position = 0)]
  [Switch]$ResetFiles
)

# Finding localpath of script
# $scriptDir = $PSScriptRoot

# Setting the file and path to a variable
# $MyLocalParameters = "$PSScriptRoot\MyLocalParameters.txt"

$MyLocalParameters = 'MyLocalParameters.txt'
Write-Verbose -Message ('Local Parameter Path: {0}' -f $MyLocalParameters)

$OriginalFile = 'MyLocalParameters.org'
Write-Verbose -Message ('Original File: {0}' -f $OriginalFile)

if($ResetFiles)
{
  Write-Verbose -Message ('Resetting the {0} back to default {1}' -f $MyLocalParameters, $OriginalFile)
  Get-ChildItem |
  Where-Object -FilterScript {
$_.BaseName -match ($OriginalFile.Split('.')[0])
} |
  ForEach-Object -Process {
Remove-Item -Path $_
}
  $HashFile = Get-ChildItem -Path '*.hash' |
  Sort-Object -Property LastWriteTime |
  Select-Object -First 1
  Rename-Item -Path $HashFile -NewName $OriginalFile

  Write-Verbose -Message ('Reset files completed')
  Start-Sleep -Seconds 3
  Return
} 

if(-not (Test-Path -Path $MyLocalParameters))
{
  Write-Verbose -Message ('{0} file does not exist. ' -f $MyLocalParameters)

  $Null = Copy-Item -Path $OriginalFile -Destination $MyLocalParameters
  Write-Verbose -Message ('{0} copied to {1}' -f $OriginalFile, $MyLocalParameters)  
  
  $HashName = ('{0}.hash' -f (Get-FileHash -Path $MyLocalParameters).hash)
  $Null = Rename-Item -Path ('{0}' -f $OriginalFile) -NewName $HashName
  Write-Verbose -Message ('Renaming the {0} to {1}' -f $OriginalFile, $HashName)
}

$CurrentHash = (Get-FileHash -Path $MyLocalParameters).hash
Write-Verbose -Message ('Retrieving the current hash of the {0}' -f $MyLocalParameters)
Write-Verbose -Message ('Current Hash: {0}' -f $CurrentHash)

if(Test-Path -Path "$CurrentHash.hash")
{
  Write-Verbose -Message ('The Test to see if {0} has been modified failed.' -f $MyLocalParameters)
  #Clear-Host
  Write-Output  -InputObject ("Edit the '{0}' file for your environment" -f $MyLocalParameters) 
  #Return
}
else
{
    Invoke-Expression -Command (Get-Content -Path $MyLocalParameters | Out-String )
    Clear-Host

    If(Test-FiberSatellite)
    {
Test-FiberSatellite @FiberSatellite
}
 
    If($InstalledSoftware)
    {
Get-InstalledSoftware @InstalledSoftware
}

    If($PrinterStatus)
    {
Test-PrinterStatus @PrinterStatus
}
  
        If($AdWorkstationConnections)
    {
      Test-AdWorkstationConnections @AdWorkstationConnections
      #Import-Csv -Path WorkstationList | Get-UpTime -ShowOfflineComputers -DisplayOnly
    }
    }
