#requires -Version 3.0

<#PSScriptInfo

.VERSION 1.7

.GUID 4f5d3d64-7d6e-407e-a902-cdbc1b6175cd

.AUTHOR Erik

.COMPANYNAME KnarrStudio

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI https://knarrstudio.github.io/ITPS.OMCS.Tools/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Returns system uptime 

#> 

[CmdletBinding()]
Param()

function Get-SystemUpTime
{
  <#
  .SYNOPSIS
  Get system last boot time and uptime for local or remote computers.

  .DESCRIPTION
  Returns the last boot time and total uptime (in hours) for one or many
  computers. The function supports querying by ComputerName (remote or local)
  or by an existing CimSession. Output can be written to the pipeline and
  optionally exported to CSV.

  .PARAMETER ComputerName
  One or many DNS/NetBIOS computer names. Defaults to the local computer.

  .PARAMETER CimSession
  One or many CimSession objects. When provided, CimSession is used instead
  of ComputerName.

  .PARAMETER ShowOfflineComputers
  When specified, the cmdlet will include an errors section listing
  computers/sessions that failed to respond.

  .PARAMETER BootOnly
  Only return the computer name and last boot time (omit TotalHours).

  .PARAMETER FileOnly
  When specified, results are written to the CSV file only (but also
  emitted to the pipeline). See OutCsv for the path.

  .PARAMETER OutCsv
  Path to the CSV file used when -FileOnly is specified. Defaults to
  "$env:TEMP\UpTime.csv".

  .EXAMPLE
  Get-SystemUpTime -ComputerName Server01,Server02

  .EXAMPLE
  $s = New-CimSession -ComputerName Server01
  Get-SystemUpTime -CimSession $s -ShowOfflineComputers

  .NOTES
  Uses Get-CimInstance for modern CIM/WMI access and works across remote
  sessions or by computer name. Maintains backward-compatible output shape.
  #>

  [cmdletbinding(DefaultParameterSetName = 'DisplayOnly')]
  Param (
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0,ParameterSetName='ByName')]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,

    [Parameter(ParameterSetName = 'ByCimSession')]
    [CimSession[]]$CimSession,

    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$ShowOfflineComputers,

    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$BootOnly,

    [Parameter (ParameterSetName = 'FileOnly')]
    [Switch]$FileOnly,

    [Parameter (ParameterSetName = 'FileOnly')]
    [String]$OutCsv = (Join-Path -Path $env:TEMP -ChildPath 'UpTime.csv')
  )

  BEGIN {
    $ErroredComputers = @()
    if ($BootOnly) { $SelectObjects = 'ComputerName','LastBoot' }
    else { $SelectObjects = 'ComputerName','LastBoot','TotalHours' }

    if ($FileOnly -and (Test-Path -Path $OutCsv)) {
      $i = 1
      $base = [IO.Path]::ChangeExtension($OutCsv, $null)
      do {
        $OutCsv = ('{0}({1}).csv' -f $base, $i)
        $i++
      } while (Test-Path -Path $OutCsv)
    }
  }

  PROCESS {
    if ($CimSession) { $Targets = $CimSession } else { $Targets = $ComputerName }

    foreach ($target in $Targets) {
      $Object = $null
      try {
        if ($CimSession) {
          $OS = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $target -ErrorAction Stop
          $Computer = ($target | Select-Object -ExpandProperty ComputerName -ErrorAction SilentlyContinue) -or $OS.__SERVER -or $target
        }
        else {
          $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $target -ErrorAction Stop
          $Computer = $target
        }

        $UpTime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
        $Properties = @{
          ComputerName = $Computer
          LastBoot     = $OS.ConvertToDateTime($OS.LastBootUpTime)
          TotalHours   = ('{0:n2}' -f $UpTime.TotalHours)
        }

        $Object = [PSCustomObject]$Properties | Select-Object -Property $SelectObjects
      }
      catch {
        if ($ShowOfflineComputers) {
          $name = if ($CimSession) { ($target | Select-Object -ExpandProperty ComputerName -ErrorAction SilentlyContinue) -or $target } else { $target }
          $ErrorMessage = ('{0} Error: {1}' -f $name, $_.Exception.Message)
          $ErroredComputers += $ErrorMessage

          $Properties = @{
            ComputerName = $name
            LastBoot     = 'Unable to Connect'
            TotalHours   = 'Error Shown Below'
          }

          $Object = [PSCustomObject]$Properties | Select-Object -Property $SelectObjects
        }
      }
      finally {
        if ($FileOnly -and $Object) {
          $Object | Export-Csv -Path $OutCsv -Append -NoTypeInformation
          Write-Verbose -Message ('Output located {0}' -f $OutCsv)
        }

        if ($Object) { Write-Output -InputObject $Object }

        Remove-Variable -Name Object -ErrorAction SilentlyContinue
        Remove-Variable -Name OS -ErrorAction SilentlyContinue
        Remove-Variable -Name UpTime -ErrorAction SilentlyContinue
        Remove-Variable -Name ErrorMessage -ErrorAction SilentlyContinue
        Remove-Variable -Name Properties -ErrorAction SilentlyContinue
      }
    }
  }

  END {
    if ($ShowOfflineComputers -and $ErroredComputers) {
      Write-Output -InputObject ''
      Write-Output -InputObject 'Errors for Computers not able to connect.'
      Write-Output -InputObject $ErroredComputers
    }
  }
}





# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQBa53k7aBXvsqSfEi9lP2S/h
# nAOgggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
# AQUFADAhMR8wHQYDVQQDDBZLbmFyclN0dWRpb1NpZ25pbmdDZXJ0MB4XDTIwMDIx
# OTIyMTUwM1oXDTI0MDIxOTAwMDAwMFowITEfMB0GA1UEAwwWS25hcnJTdHVkaW9T
# aWduaW5nQ2VydDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAxtuEswl88jvC
# o69/eD6Rtr5pZikUTNGtI2LqT1a3CZ8F6BCC1tp0+ftZLppxueX/BKVBPTTSg/7t
# f5nkGMFIvbabMiYtfWTPr6L32B4SIZayruDkVETRH74RzG3i2xHNMThZykUWsekN
# jAer+/a2o7F7G6A/GlH8kan4MGjo1K0CAwEAAaNGMEQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFGp363bIyuwL4FI0q36S/8cl5MOBMA4GA1UdDwEB/wQE
# AwIHgDANBgkqhkiG9w0BAQUFAAOBgQBkVkTuk0ySiG3DYg0dKBQaUqI8aKssFv8T
# WNo23yXKUASrgjVl1iAt402AQDHE3aR4OKv/7KIIHYaiFTX5yQdMFoCyhXGop3a5
# bmipv/NjwGWsYrCq9rX2uTuNpUmvQ+0hM3hRzgZ+M2gmjCT/Pgvia/LJiHuF2SlA
# 7wXAuVRh8jGCAVUwggFRAgEBMDUwITEfMB0GA1UEAwwWS25hcnJTdHVkaW9TaWdu
# aW5nQ2VydAIQapk6cNSgeKlJl3aFtKq3jDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUwzKQfHuJ
# pvnNm6gpeKEzildgc3UwDQYJKoZIhvcNAQEBBQAEgYBPvG3Il1ohuO3zHbRBskRp
# zCQeB+StRxo2FdvfIiZQFO1Th7oytfJxdh/oAWqQTGlh0VVfjaV59Dxcjp+ou0pS
# BqyJMQ69Amy7LypysHAWQT70VHnAhMUF2sCCoiTv9WgrQ1764wIoHzlOpgd/jMqT
# DES820Hspcjw5B2WsGAzYA==
# SIG # End signature block
