function Repair-WindowsUpdate
{
  #requires -Version 3.0
  <#PSScriptInfo
    
      .VERSION 2.0
    
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
 BEGIN {
    $asAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $UpdateServices = 'wuauserv', 'cryptSvc', 'bits', 'msiserver'
    $RenameFiles = "$env:windir\SoftwareDistribution", "$env:windir\System32\catroot2"

    function Set-ServiceState {
        <#
            .SYNOPSIS
            Starts or stops services based on the "Stop / Start" switch.
        #>
        param(
            [Parameter(Mandatory, HelpMessage = 'List of services to stop or start.')][string[]]$services,
            [Switch]$Stop,
            [Switch]$Start
        )
        if ($Stop) {
            foreach ($service in $services) {
                try {
                    Stop-Service -Name $service -PassThru
                } catch {
                    Stop-Service -Name $service -Force
                }
            }
        }
        if ($Start) {
            foreach ($service in $services) {
                Start-Service -Name $service
            }
        }
    }

    function Rename-Files {
        <#
            .SYNOPSIS
            Renames files by appending ".old" to their names.
        #>
        param(
            [Parameter(Mandatory, HelpMessage = 'List of files to be renamed with ".old".')][string[]]$Files
        )
        foreach ($File in $Files) {
            Rename-Item -Path $File -NewName ("$File.old") -Force
        }
    }
}

PROCESS {
    if ($asAdmin) {
        Set-ServiceState -services $UpdateServices -Stop
        Rename-Files -Files $RenameFiles
        Set-ServiceState -services $UpdateServices -Start
    } else {
        Write-Host '*** Please re-run as an administrator ***' -ForegroundColor Black -BackgroundColor Yellow
    }
}

END { 
}
}

