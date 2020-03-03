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
