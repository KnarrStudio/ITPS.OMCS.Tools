#requires -Version 3.0
  <#PSScriptInfo

      .VERSION 1.3

      .GUID ffd1c052-9783-4fe0-afff-76d070421959

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

  function Get-FolderRedirection
{

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
        if($KeyIndex -ne $CurrentIndex){
            $KeyIndex = $CurrentIndex
            $CompareList += $RegKey.ToString()
        }



        foreach($FolderKey in $FolderList.keys)
    {
      Write-Verbose -Message ('FolderName = {0}' -f $FolderName)
      Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
      Write-Verbose -Message ('FolderKey = {0}' -f $FolderKey)
        Write-Verbose -Message ('RegKey = {0}' -f $RegKey)
        
        $FolderName = $FolderList.Item($FolderKey)
      $OldPath = ('{0}\{1}' -f $LocalPath, $FolderName)
      $LeafKey = Split-Path -Path $RegKey -Leaf
        $CurrentSettings = Get-ItemProperty -Path $RegKey -Name $FolderKey
        $newlist = ('{2}: {0} = {1}' -f $FolderKey, $CurrentSettings.$FolderKey, $LeafKey)
        Write-Verbose -Message $newlist
        $CompareList += $newlist
       
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

function Set-FolderRedirection
{

  <#
      .SYNOPSIS
      Change the user's folder redirection.

      .DESCRIPTION
      From a normal Powershell console. 
      The script will set the folder redirection to what is specified in the -RemotePath Parameter.  Then it will copy any file that is in the "old path" to the new path if the -NoCopy parameter is not set (default).

      .PARAMETER RemotePath
      Makes changes to the home folders based on what you put here.  Such as - "H:\_MyComputer".

      .PARAMETER NoCopy
      Stops the items in the old path, most of the time 'local' to the new path.

      .PARAMETER Quiet
      Suppresses output to console

      .PARAMETER errorlog
      Change the default locaion of the log - Default = "$env:TEMP\ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt"
      
      .PARAMETER resultlog
      Change the default locaion of the log - Default = "$env:TEMP\FolderRedirection-$($env:USERNAME).log"
      
      .EXAMPLE
      Set-FolderRedirection -RemotePath 'H:\_MyComputer'
      This will redirect the folders to the path on the "H:" drive.  You must use the 'Repair' parameter if you want to make changes.

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
    # $RemotePath Path to the Users's home drive if "remotepath" is not set.  Often the 'H:' drive.
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName,Position = 0)]
    [string]$RemotePath,
    [Switch]$NoCopy,
    [Switch]$Quiet,
    [string]$errorlog = "$env:TEMP\ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt",
    [string]$resultlog = "$env:TEMP\FolderRedirection-$($env:USERNAME).log"

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
    #$errorlog = "ErrorLog-FolderRedirection-$(Get-Date -UFormat %d%S).txt"
    #$resultlog = "$env:TEMP\FolderRedirection-$($env:USERNAME).log"
  }
  Process
  {
    # The reason for looping through the FolderList first instead of the Registry Keys is to find out which of the folders have been redirected first.
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
        try
        {
        New-Item -Path $NewPath -ItemType Directory -ErrorAction Stop
        }
        catch
        {
        Write-Output -InputObject ('Error File: {0}' -f $errorlog)
        $null = $NewPath + $_.Exception.Message | Out-File -FilePath $errorlog -Append        
        }
      }

      if(-not $NoCopy){
          Write-Verbose -Message ('OldPath = {0}' -f $OldPath)
          try
             {
                Copy-Item -Path $OldPath -Destination $RemotePath -Force -Recurse -ErrorAction Stop
      }
          catch
             {
        Write-Output -InputObject ('Error File: {0}' -f $errorlog)
        $null = $OldPath + $_.Exception.Message | Out-File -FilePath $errorlog -Append
      }
      }

      foreach($RegKey in $Keys)
      {
        Write-Verbose -Message ('FolderKey = {0}' -f $FolderKey)
        Write-Verbose -Message ('FolderName = {0}' -f $FolderName)
        Write-Verbose -Message ('RegKey = {0}' -f $RegKey)
        
        $LeafKey = Split-Path -Path $RegKey -Leaf
        #$LeafKey = Split-Path -Path $Keys[0] -Leaf
        $CurrentSettings = Get-ItemProperty -Path $RegKey -Name $FolderKey
        $newlist = ('{2}: {0} = {1}' -f $FolderKey, $CurrentSettings.$FolderKey, $LeafKey)
        Write-Verbose -Message $newlist
        $CompareList += $newlist
       
        <# F8 Testing --
            $Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
            Get-ItemProperty -Path $key
        #>


        # This is the command that actually makes changes to the Registry 
        Set-ItemProperty -Path $RegKey -Name $FolderKey -Value $NewPath -WhatIf
      }
    }
    
  }

  END {
    if(-not $Quiet)
    {
      $CompareList | Sort-Object
      Write-Output -InputObject ('Log File: {0}' -f $resultlog)
          }
    $CompareList |
    Sort-Object |
    Out-File -FilePath $resultlog
  }
}