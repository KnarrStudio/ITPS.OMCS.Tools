function Get-InstalledSoftware
{
  <#
    Archived/disabled stub for Get-InstalledSoftware

    The full implementation was moved to `Modules\_Archived\Get-InstalledSoftware.psm1`.
    If you need to restore the command, copy the archived implementation back
    into this module or dot-source the archived file.
  #>

  [CmdletBinding()]
  Param()

  Write-Warning 'Get-InstalledSoftware is archived. See Modules\_Archived\Get-InstalledSoftware.psm1 for the original implementation.'
}

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
