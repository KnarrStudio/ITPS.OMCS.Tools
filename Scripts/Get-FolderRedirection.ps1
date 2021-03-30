#requires -Version 3.0
function Get-FolderRedirection
{
  <#PSScriptInfo

      .VERSION 1.3

      .GUID c8170885-61c4-4018-97d3-6546c71f9b81

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
      Verify the user's folder redirection.

      .DESCRIPTION
      From a normal Powershell console. 
      The script will verify that the path exists and displays it to the console.  
      This should be run prior to imaging a user's workstaion.

      .PARAMETER RemotePath
      Makes changes to the home folders based on what you put here.  Such as - "$env:HOMEDRIVE\_MyComputer".

      .PARAMETER Repair
      Initiats the changes

      .PARAMETER Silent
      Suppresses output to console

      .EXAMPLE
      Get-FolderRedirection -RemotePath 'H:\_MyComputer' -Repair
      This will redirect the folders to the path on the "H:" drive.  You must use the 'Repair' parameter if you want to make changes.

      .EXAMPLE
      Get-FolderRedirection
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
    $Keys | ForEach-Object {Write-Output('Registry Key: {0}' -f $_)}
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
            Get-ItemProperty -Path $key
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
# Get-FolderRedirection -Silent
# Get-FolderRedirection -Repair -RemotePath h:\_MyComputer -Confirm 


