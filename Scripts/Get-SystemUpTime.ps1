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
      Short Description
      .DESCRIPTION
      Detailed Description
      .EXAMPLE
      Get-SystemUpTime
      explains how to use the command
      can be multiple lines
      .EXAMPLE
      Get-SystemUpTime
      another example
      can have as many examples as you like
  #>
  <# 
      .SYNOPSIS
      Returns the last boot time and uptime in hours for one or many computers
    
      .DESCRIPTION 
      Returns system uptime
    
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
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$ShowOfflineComputers,
    <# [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$DisplayOnly,#>
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
        
        $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property $SelectObjects
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
          
          $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property $SelectObjects
        }
      }
      finally 
      {
        if($FileOnly)
        {
          $Object | Export-Csv -Path $OutCsv -Append -NoTypeInformation
          Write-Verbose -Message ('Output located {0}' -f $OutCsv)
        }
        
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



# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH1A5K7X7b9++bpYOlCYOGvm9
# BAOgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU3YF2o3qRDXYU2vNrC4jIDxjTapIw
# DQYJKoZIhvcNAQEBBQAEgYA1XzqQ2frU2sAdSM9ie6KkBw8K4R1Uj3npZE8a3Kg3
# oOA39NtG7aN+zSlW7uiCxi6t8Hnk4OxLGOswfaxW8lRe/u/3hHeY1txmiP9qBtzp
# urHbPSea0tnAzQmAXjHxLW1KAODjvijvVz4Xe95fxfKAQ+LU0xWSAEHQPzwsyqxz
# PA==
# SIG # End signature block
