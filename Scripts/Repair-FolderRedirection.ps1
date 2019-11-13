#requires -Version 3.0
function Repair-FolderRedirection
{
  <#
      .SYNOPSIS
      Changes the folder redirectionsettings in the registry.  This should be run prior to imaging a user's workstaion.

      .DESCRIPTION
      The script with verify that the path exists, and copies all of the local files to the "Remote" location, then changes the registry to mach that remote location.

      .PARAMETER TestSettings
      Makes no changes but allows you to varify the settings.
      
      .PARAMETER RemotePath
      Makes changes and repairs the path to the home folders based on what you put here.  Such as - "$env:HOMEDRIVE\_MyComputer".

      .PARAMETER RepairSettings
      Sets the "What if" statment to $False

      .EXAMPLE
      Repair-FolderRedirection -RemotePath 'H:\_MyComputer' -RepairSettings
      This will redirect the folders to the path on the "H:" drive.  You must use the 'RepairSettings' parameter if you want to make changes.

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
    [Switch]$RepairSettings,
    [Parameter (ParameterSetName = 'TestSettings')]
    [Switch]$TestSettings
  )
  
  Begin
  {
    $ConfirmPreference = 'High'
    $WhatIfPreference = $true
    if($RepairSettings)
    {
      $WhatIfPreference = $false
    }
    
    $CompareList = @()

    $FolderList = @{
      'Desktop'   = 'Desktop'
      'Favorites' = 'Favorites'
      'My Music'  = 'Music'
      'My Pictures' = 'Pictures'
      'My Video'  = 'Videos'
      'Personal'  = 'Documents'
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
# MIIELQYJKoZIhvcNAQcCoIIEHjCCBBoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNAfRGaSQaiUkkVNWgyVKRzfh
# SE2gggI9MIICOTCCAaagAwIBAgIQrlm6Ux0pS6dCo5jAo/sDXjAJBgUrDgMCHQUA
# MCYxJDAiBgNVBAMTG1Bvd2VyU2hlbGwgVGVzdCBDZXJ0aWZpY2F0ZTAeFw0xOTEx
# MDMwMjQwMzNaFw0zOTEyMzEyMzU5NTlaMCYxJDAiBgNVBAMTG1Bvd2VyU2hlbGwg
# VGVzdCBDZXJ0aWZpY2F0ZTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1dYD
# /5l3p81jypA2wG5peOY1p29/afYZh+TYbSHDS6lRcGivq1XFVMoByevWwt4Z21mm
# eeCAKhdEXmOLYwSV0o+jkM8ua5P/uA5ujJDtFWL6SWF3r4n3YApCN7868kvFJnlG
# Eefj3kbh4JDxPZihyu2fJDPAZ0HFRF5DKkyvVikCAwEAAaNwMG4wEwYDVR0lBAww
# CgYIKwYBBQUHAwMwVwYDVR0BBFAwToAQSlFU+nlcnZBvT7LrwisufqEoMCYxJDAi
# BgNVBAMTG1Bvd2VyU2hlbGwgVGVzdCBDZXJ0aWZpY2F0ZYIQrlm6Ux0pS6dCo5jA
# o/sDXjAJBgUrDgMCHQUAA4GBAEr2UlpPCGyRwgqd12ujqnMMBaJWVyHjTYCQYqtn
# B8oh7Y7zFTLOxrqaBxN46v57uni+xogbxdodd6KPhv2aF8+f34X2rTamsthAksGq
# wrv5JTUooU7lHM5eX3EjAs5EO9c3O/jWUfHj3JbmGj+81XFFr6s6On9oPyIZNdYG
# Ds67MYIBWjCCAVYCAQEwOjAmMSQwIgYDVQQDExtQb3dlclNoZWxsIFRlc3QgQ2Vy
# dGlmaWNhdGUCEK5ZulMdKUunQqOYwKP7A14wCQYFKw4DAhoFAKB4MBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFL8EINjm
# SbyYNJKt66JDfafAmx9pMA0GCSqGSIb3DQEBAQUABIGAj7wCFIoZ4rB8jsMAEpaX
# 6Mp1WGLipL3DMGQuyY+EDG5gQGnleDVc/JHzCgXpZEuMk8yPWiQvxNGLZycQeSKt
# 3hV5Qo8+QU/sGDXxX0msvs6O9tVYPFzoRw1T/BM0G//y5us444gZYSpu3Gv3HoT5
# xcRZCif4mQAxaDtfOA+XTqs=
# SIG # End signature block
