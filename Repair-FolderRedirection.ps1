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
