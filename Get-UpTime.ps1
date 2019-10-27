#requires -Version 3.0
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

  [cmdletbinding(DefaultParameterSetName = 'DisplayOnly')]
  Param (
    [Parameter(ParameterSetName = 'DisplayOnly',ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$ShowOfflineComputers,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$DisplayOnly,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$BootOnly,
    [Parameter (ParameterSetName = 'FileOnly')]
    [Switch]$FileOnly,
    [Parameter (ParameterSetName = 'FileOnly')]
    [String]$OutCsv = "$env:HOMEDRIVE\Temp\UpTime.csv"
  )
 
  BEGIN {
    $ErroredComputers = @()
    if($BootOnly)
    {
      $SelectObjects = 'ComputerName', 'LastBoot'
    }
    else
    {
      $SelectObjects = 'ComputerName', 'LastBoot', 'TotalHours'
    }
    if($DisplayOnly)
    {
      $OutCsv = $null
    }
    if($FileOnly)
    {
      if (Test-Path -Path $OutCsv)
      {
        $i = 1
        $NewFileName = $OutCsv.Trim('.csv')
        Do 
        {
          $OutCsv = ('{0}({1}).csv' -f $NewFileName, $i)
          $i++
        }while (Test-Path -Path $OutCsv)
      }
    }
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
          TotalHours   = ( '{0:n2}' -f $UpTime.TotalHours)
        }

        $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -ExpandProperty $SelectObjects
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
            TotalHours   = 'Error Shown Below'
          }

          $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -ExpandProperty $SelectObjects
        }
      }
      finally 
      {
        if($FileOnly)
        {
          $Object | Export-Csv -Path $OutCsv -Append -NoTypeInformation
          Write-Verbose -Message ('Output located {0}' -f $OutCsv)
        }
        if($DisplayOnly)
        {
          Write-Output $Object
        }

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
      Write-Output ''
      Write-Output 'Errors for Computers not able to connect.'
      Write-Output $ErroredComputers
    }
  }
}

# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEWy86joWGz9Ly5SH8nvpMZhd
# FFSgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
# MBYxFDASBgNVBAMTC0VyaWtBcm5lc2VuMB4XDTE3MTIyOTA1MDU1NVoXDTM5MTIz
# MTIzNTk1OVowFjEUMBIGA1UEAxMLRXJpa0FybmVzZW4wgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBAKYEBA0nxXibNWtrLb8GZ/mDFF6I7tG4am2hs2Z7NHYcJPwY
# CxCw5v9xTbCiiVcPvpBl7Vr4I2eR/ZF5GN88XzJNAeELbJHJdfcCvhgNLK/F4DFp
# kvf2qUb6l/ayLvpBBg6lcFskhKG1vbEz+uNrg4se8pxecJ24Ln3IrxfR2o+BAgMB
# AAGjYDBeMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEcGA1UdAQRAMD6AEMry1NzZravR
# UsYVhyFVVoyhGDAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlboIQyWSKL3Rtw7JMh5kR
# I2JlijAJBgUrDgMCHQUAA4GBAF9beeNarhSMJBRL5idYsFZCvMNeLpr3n9fjauAC
# CDB6C+V3PQOvHXXxUqYmzZpkOPpu38TCZvBuBUchvqKRmhKARANLQt0gKBo8nf4b
# OXpOjdXnLeI2t8SSFRltmhw8TiZEpZR1lCq9123A3LDFN94g7I7DYxY1Kp5FCBds
# fJ/uMYIBSjCCAUYCAQEwKjAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlbgIQyWSKL3Rt
# w7JMh5kRI2JlijAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU/p43yh2NQRtKZwiAFbztcLBqjQEw
# DQYJKoZIhvcNAQEBBQAEgYB2OCKYXkA85ayP6jeoAKmr5rqHekLntaM/4vrD8ecv
# BJAw7zsQGLG5/bwHQkolOYppmx4etvcx7ZGosr4pwutJGhpneqwKPSPANWQqf8HA
# XsvFLAZJ7Ecd+3NJcvXvztsj/gMIv4Mhm15o4pp8zWw49YZtcpv/a0uIr9JFLBDG
# Sw==
# SIG # End signature block
