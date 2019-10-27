#requires -Version 3.0
function Repair-FolderRedirection
{
  <#
      .SYNOPSIS
      Changes the folder redirectionsettings in the registry.  This should be run prior to imaging a user's workstaion.

      .DESCRIPTION
      The script with verify that the path exists, and copies all of the local files to the "Remote" location, then changes the registry to mach that remote location.

      .PARAMETER RemotePath
      Makes changes and repairs the path to the home folders.

      .PARAMETER TestSettings
      Makes no changes but allows you to varify the settings.

      .EXAMPLE
      Repair-FolderRedirection -RemotePath 'H:\_MyComputer'
      This will redirect the folders to the path on the "H:" drive.

      .EXAMPLE
      Repair-FolderRedirection -TestSettings
      Sends the current settings to the screen
      
  #>
  
  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'High')]
  [OutputType([int])]
  Param
  (
    # $RemotePath Path to the Users's 'H:' drive
    [Parameter(ParameterSetName = 'Repair',ValueFromPipelineByPropertyName,Position = 0)]
    [string]$RemotePath = "$env:HOMEDRIVE\_MyComputer",
    [Parameter(ParameterSetName = 'Repair')]
    [Switch]$go,
    [Parameter (ParameterSetName = 'TestSettings')]
    [Switch]$TestSettings
  )
  
  Begin
  {
    $CompareList = @()

    $FolderList = @{
      'Desktop'   = 'Desktop'
      'Favorites' = 'Favorites'
      'My Music'  = 'Music'
      'My Pictures' = 'Pictures'
      'My Video'  = 'Videos'
      'Personal'  = 'Documents'
    }
    
    $WhatIfPreference = $true
    if($go){
    $WhatIfPreference = $false
    }

    $Keys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
    $LocalPath = $Env:USERPROFILE
    $errorlog = "ErrorLog-$(Get-Date -UFormat %d%S).txt"
  }
  Process
  {
    foreach($FolderKey in $FolderList.keys)
    {
      $FolderName = $FolderList.Item($FolderKey)
      $OldPath = ('{0}\{1}' -f $LocalPath, $FolderName)
      $NewPath = ('{0}\{1}' -f $RemotePath, $FolderName)
      Write-Verbose -Message ('FolderName = {0}' -f $FolderName)
      Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
      Write-Verbose -Message ('NewPath = {0}' -f $NewPath)

      If(-Not(Test-Path -Path $NewPath ))
      {
        Write-Verbose -Message ('NewPath = {0}' -f $NewPath)
        if(-Not $TestSettings)
        {
          New-Item -Path $NewPath -ItemType Directory
        }
      }

      Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
      try
      {
       if(-Not $TestSettings)
        {
          Copy-Item -Path $OldPath -Destination $RemotePath -Force -Recurse -ErrorAction Stop
        }
      }
      catch
      {
        $OldPath + $_.Exception.Message | Out-File -FilePath ('{0}\{1}' -f $RemotePath, $errorlog) -Append
      }
      
      foreach($RegKey in $Keys)
      {
        Write-Verbose -Message ('FolderKey = {0}' -f $FolderKey)
        Write-Verbose -Message ('FolderName = {0}' -f $FolderName)
        Write-Verbose -Message ('RegKey = {0}' -f $RegKey)
        

        $LeafKey = Split-Path -Path $RegKey -Leaf
        $CurrentSettings = Get-ItemProperty -Path $RegKey -Name $FolderKey
        $newlist = ('{2}: {0} = {1}' -f $FolderKey, $CurrentSettings.$FolderKey, $LeafKey)
        Write-Verbose -Message $newlist
        $CompareList += $newlist
       
        <# F8 Testing::

            $Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
            Get-ItemProperty -Path $key
       
        ::Testing #>

        if(-Not $TestSettings)
        {
          Set-ItemProperty -Path $RegKey -Name $FolderKey -Value $NewPath
        }
      }
    }

  }

  END {
    if($TestSettings)
    {
      $CompareList | Sort-Object
    }
  }
}

# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUg0WxvBiasTONgku/ywjSo67J
# a/ygggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU0xYxrrAzCQXwPSAGmtPMoyja7uow
# DQYJKoZIhvcNAQEBBQAEgYA3YKsA5m4pXRJ2RpixT9/1VG2lKzQn/sYbhRQOUpdK
# wxHqmoT/m+jCrSdgu3/80ej3hETMoNPhEMxJaVVUZPd790vVBs8VBBkMsP3/biCw
# ki7IwcQVG7vFxPeXoaFsS8j/Cc78wEa+E0mq8kB/SDw+4+9XvnkLgYxP1a6SQ8uy
# 2w==
# SIG # End signature block
