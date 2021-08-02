function Repair-WindowsUpdate
{
  #requires -Version 3.0
  <#PSScriptInfo
    
    .VERSION 1.0
    
    .GUID ebdf766e-f61c-49a4-a764-1102ed0ac4dc
    
    .AUTHOR Erik@home
    
    .COMPANYNAME KnarrStudio
    
    .COPYRIGHT 2021 KnarrStudio
    
    .RELEASENOTES
    Quick script to automate a manual process
    
  #>
  <#
    .SYNOPSIS
    Automates the steps used to repair Windows Updates. 
    
    .DESCRIPTION
    Automates the steps used to repair Windows Updates. 
    The steps can be found in the Advanced section of the "Troubleshoot problems updating Windows 10" page. See link
    
    PowerShells the following steps:
    net.exe stop wuauserv 
    net.exe stop cryptSvc 
    net.exe stop bits 
    net.exe stop msiserver 
    ren C:\Windows\SoftwareDistribution -NewName SoftwareDistribution.old 
    ren C:\Windows\System32\catroot2 -NewName Catroot2.old 
    net.exe start wuauserv 
    net.exe start cryptSvc 
    net.exe start bits 
    net.exe start msiserver 
    
    
    .EXAMPLE
    As an admin, run: Repair-WindowsUpdate
    
    .NOTES
    
    
    .LINK
    https://support.microsoft.com/help/4089834?ocid=20SMC10164Windows10
    
  #>
  
  $UpdateServices = 'wuauserv', 'cryptSvc', 'bits', 'msiserver'
  $RenameFiles = "$env:windir\SoftwareDistribution", "$env:windir\System32\catroot2"
  function Set-ServiceState 
  {
    <#
      .SYNOPSIS
      Start or stop Services based on "Stop / Start" switch
    #>
    param(
      [Parameter(Mandatory,HelpMessage = 'list of services that to stop or start')][string[]]$services,
      [Switch]$Stop,
      [Switch]$Start
    )
    if ($Stop)
    {
      ForEach ($service in $services)
      {
        try
        {
          Stop-Service -InputObject $service -PassThru
        }
        catch
        {
          Stop-Service -InputObject $service -Force
        }
      }
    }
    if ($Start)
    {
      ForEach ($service in $services)
      {
        Start-Service -InputObject $service
      }
    }
  }
  function Rename-Files
  {
    <#
      .SYNOPSIS
      Renames files to ".old"
    #>
    param(
      [Parameter(Mandatory,HelpMessage = 'list of files to be renamed with ".old"')][string[]]$Files
    )
    ForEach($File in $Files)
    {
      Rename-Item -Path $File -NewName ('{0}.old' -f $File) -Force
    }
  }
  Set-ServiceState -services $UpdateServices -Stop
  Rename-Files -Files $RenameFiles
  Set-ServiceState -services $UpdateServices -Start
}

