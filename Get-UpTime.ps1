Function Get-UpTime 
{
  <#
    .SYNOPSIS
    Returns the last boot time and uptime in hours for one or many computers

    .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER ComputerName
    One or Many Computers

    .PARAMETER ShowOfflineComputers
    Returns a list of the computers that did not respond.

    .EXAMPLE
    Get-UpTime -ComputerName Value -ShowOfflineComputers
    Returns the last boot time and uptime in hours of the list of computers in "value" and lists the computers that did not respond

    .OUTPUTS
    ComputerName LastBoot           TotalHours       
    ------------ --------           ----------       
    localhost    10/9/2019 00:09:28 407.57           
    tester       Unable to Connect  Error Shown Below

    Errors for Computers not able to connect.
    tester Error: The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
  #>


  Param (
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [Switch]$ShowOfflineComputers
  )
 
  BEGIN {
  $ErroredComputers = @()
  }
 
  PROCESS {
    Foreach ($Computer in $ComputerName) 
    {
      Try 
      {
        $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
        $UpTime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
        $Properties = @{
          ComputerName = $Computer
          LastBoot     = $OS.ConvertToDateTime($OS.LastBootUpTime)
          TotalHours       = ( '{0:n2}' -f $UpTime.TotalHours)
        }
 
        $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property ComputerName, LastBoot, TotalHours
      }
      catch 
      {
        if ($ShowOfflineComputers) 
        {
          $ErrorMessage = ('{0} Error: {1}' -f $Computer, $_.Exception.Message)
          $ErroredComputers += $ErrorMessage
 
          $Properties = @{
            ComputerName = $Computer
            LastBoot     = 'Unable to Connect'
            TotalHours       = 'Error Shown Below'
          }

          $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property ComputerName, LastBoot, TotalHours
        }
      }
      finally 
      {
        Write-Output -InputObject $Object
 
        $Object       = $null
        $OS           = $null
        $UpTime       = $null
        $ErrorMessage = $null
        $Properties   = $null
      }
    }
  }
 
  END {
      if ($ShowOfflineComputers) 
    {
      Write-Output -InputObject ''
      Write-Output -InputObject 'Errors for Computers not able to connect.'
      Write-Output -InputObject $ErroredComputers
    }
  }
}