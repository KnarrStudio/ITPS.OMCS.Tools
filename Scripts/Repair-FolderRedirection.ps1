#requires -Version 3.0
function Repair-FolderRedirection
{
  <#PSScriptInfo

      .VERSION 1.3

      .GUID cc7ee278-5103-4711-909c-315e3915ba92

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Folder Redirecton Self Help 

      .LICENSEURI

      .PROJECTURI https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES 

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES


      .PRIVATEDATA

  #>
  <#
      .SYNOPSIS
      Verify and repair (redirect) the user's folder redirection.

      .DESCRIPTION
      From a normal Powershell console. 
      The script will verify that the path exists, and copies all of the local files to the "Remote" location, then changes the registry to mach that remote location.  
      Changes the folder redirection settings in the registry.  
      This should be run prior to imaging a user's workstaion.

      .PARAMETER RemotePath
      Makes changes to the home folders based on what you put here.  Such as - "$env:HOMEDRIVE\_MyComputer".

      .PARAMETER Repair
      Initiats the changes

      .PARAMETER Silent
      Suppresses output to console

      .EXAMPLE
      Repair-FolderRedirection -RemotePath 'H:\_MyComputer' -Repair
      This will redirect the folders to the path on the "H:" drive.  You must use the 'Repair' parameter if you want to make changes.

      .EXAMPLE
      Repair-FolderRedirection
      Sends the current settings to the screen

      .NOTES
      Really written to standardize the troubleshooting and repair of systems before they are imaged to prevent data loss.

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .INPUTS
      Remote path as a string

      .OUTPUTS
      Display to console.
  #>

  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'High')]
  [OutputType([int])]
  Param
  (
    # $RemotePath Path to the Users's 'H:' drive
    [Parameter(ParameterSetName = 'Repair',ValueFromPipelineByPropertyName,Position = 0)]
    [string]$RemotePath = "$env:HOMEDRIVE\_MyComputer",
    # Use the Repair switch make changes to settings
    [Parameter(ParameterSetName = 'Repair')]
    [Switch]$Repair,
    [Switch]$Silent
  )
 
  Begin
  {
    $ConfirmPreference = 'High'
   
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
    $errorlog = "ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt"
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
        if($Repair)
        {
          New-Item -Path $NewPath -ItemType Directory
        }
      }

      Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
      try
      {
        if($Repair)
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
       
        <# F8 Testing --
            $Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
            Get-ItemProperty -Path $ke
        #>

        if($Repair)
        {
          Set-ItemProperty -Path $RegKey -Name $FolderKey -Value $NewPath
        }
      }
    }

  }

  END {
    if(-not $Silent)
    {
      $CompareList | Sort-Object
      Write-Output -InputObject 'Log File: ', $env:TEMP\FolderRedirection.log""
    }
    $CompareList |
    Sort-Object |
    Out-File -FilePath "$env:TEMP\FolderRedirection.log"
  }
}


# Testing:
# Repair-FolderRedirection -Silent
# Repair-FolderRedirection -Repair -RemotePath h:\_MyComputer -Confirm 






# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/T9SUBgOtbwsBe7QeRi+r3xO
# F++gggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUdNPde3bh
# 4lLZoCGQXvW71q81I2cwDQYJKoZIhvcNAQEBBQAEgYAbk/9AWqDvQZzsRxNi6NFg
# /8otKzQJrSZP7/g0uqPSuLzefaR0AIrsw/Y71Oocv42t7dyPLClyMPIkzpiiLr7+
# Qx9ebNzMNu4/Ib76TXsTbKuEF+DHtLuj2iPwVyk91AJCe+lHJ+o6I79dvbbQQiPf
# jEORfdKWOYOBIewG8tLqeg==
# SIG # End signature block
