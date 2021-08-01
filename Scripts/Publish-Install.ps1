#!/usr/bin/env powershell
#requires -Version 2.0 -Modules PowerShellGet

$PSGallery = 'NasPSGallery'
$ModuleName = 'ITPS.OMCS.Tools'

if(Test-Path -Path $env:USERPROFILE\Documents\GitHub)
{
  $ModuleLocation = "$env:USERPROFILE\Documents\GitHub\"
}
elseif(Test-Path -Path D:\GitHub\KnarrStudio)
{
  $ModuleLocation = 'D:\GitHub\KnarrStudio\'
}
Set-Location -Path $ModuleLocation

$PublishSplat = @{
  Name       = ('{0}\{1}' -f $ModuleLocation, $ModuleName)
  Repository = $PSGallery
}

$InstallSplat = @{
  Name         = $ModuleName
  Repository   = $PSGallery
  Scope        = 'CurrentUser'
  AllowClobber = $true
  Force        = $true
}


Publish-Module @PublishSplat 
#Install-Module @InstallSplat

