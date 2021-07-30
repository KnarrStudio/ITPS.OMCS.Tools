function Get-FolderRedirection
{
  <#PSScriptInfo

      .VERSION 1.3

      .GUID 0786a98d-55c0-46a3-9fcf-ed33512b2ff7

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

      .PARAMETER Quiet
      Suppresses output to console

      .EXAMPLE
      Get-FolderRedirection
      Sends the current settings to the screen

      .EXAMPLE 
      Get-FolderRedirection -Quiet
      This will do the same as default, but will not show on the console, so the file will have to be opened.  
      If using this switch, it would be best to use the -errorlog and -resultlog parameters to ensure you know where the files will be stored.

      .EXAMPLE
      Get-FolderRedirection -errorlog
      Allows you to set the location and name of the error log.  
      Default =  "$env:TEMP\ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt"
      
      .EXAMPLE
      Get-FolderRedirection -resultlog
      Allows you to set the location and name of the result log.
      Default = "$env:TEMP\FolderRedirection-$($env:COMPUTERNAME)-$($env:USERNAME).log"

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
    [Parameter(ValueFromPipelineByPropertyName,Position = 0)]
    [Switch]$Quiet,
    [string]$errorlog = "$env:TEMP\ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt",
    [string]$resultlog = "$env:TEMP\FolderRedirection-$($env:COMPUTERNAME)-$($env:USERNAME).log"

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

  }

  PROCESS
  {
    
      
    $KeyIndex = $null
    foreach($RegKey in $Keys)
    {
      $CurrentIndex = [array]::indexof($Keys,$RegKey)
      Write-Verbose  -Message ('CurrentIndex = {0}' -f $CurrentIndex)
      if($KeyIndex -ne $CurrentIndex)
      {
        $KeyIndex = $CurrentIndex
        $CompareList += $RegKey.ToString()
      }

      foreach($FolderKey in $FolderList.keys)
      {
        $FolderName = $FolderList.Item($FolderKey)
        $OldPath = ('{0}\{1}' -f $LocalPath, $FolderName)
        $LeafKey = Split-Path -Path $RegKey -Leaf
        $CurrentSettings = Get-ItemProperty -Path $RegKey -Name $FolderKey
        $newlist = ('{2}: {0} = {1}' -f $FolderKey, $CurrentSettings.$FolderKey, $LeafKey)
        Write-Verbose -Message $newlist
        $CompareList += $newlist
        
        Write-Verbose -Message ('FolderName = {0}' -f $FolderName)
        Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
        Write-Verbose -Message ('FolderKey = {0}' -f $FolderKey)
        Write-Verbose -Message ('RegKey = {0}' -f $RegKey)
        
        <# F8 Testing --
            $Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
            Get-ItemProperty -Path $key
        #>
      }
    }
  }

  END {
    if(-not $Quiet)
    {
      $CompareList  
      Write-Output -InputObject ('Log File: {0}' -f $resultlog)
    }
    $CompareList | Out-File -FilePath $resultlog
  }
}