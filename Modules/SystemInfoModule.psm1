Function Get-InstalledSoftware
{
  <#
      .SYNOPSIS
      "Get-InstalledSoftware" collects all the software listed in the Uninstall registry.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER SortList
      Allows you to sort by Name, Installed Date or Version Number.  'InstallDate' or 'DisplayName' or 'DisplayVersion'

      .PARAMETER SoftwareName
      This wil provide the installed date, version, and name of the software in the "value".  You can use part of a name or two words, but they must be in quotes.  Mozil or "Mozilla Firefox"

      .PARAMETER File
      Future Use:  Will be used to send to a file instead of the screen. 

      .EXAMPLE
      Get-InstalledSoftware -SortList DisplayName

      InstallDate  DisplayVersion   DisplayName 
      -----------  --------------   -----------
      20150128     6.1.1600.0       Windows MultiPoint Server Log Collector 
      02/06/2007   3.1              Windows Driver Package - Silicon Labs Software (DSI_SiUSBXp_3_1) USB  (02/06/2007 3.1) 
      07/25/2013   10.30.0.288      Windows Driver Package - Lenovo (WUDFRd) LenovoVhid  (07/25/2013 10.30.0.288)


      .EXAMPLE
      Get-InstalledSoftware -SoftwareName 'Mozilla Firefox',Green,vlc 

      Installdate  DisplayVersion  DisplayName                     
      -----------  --------------  -----------                     
      69.0            Mozilla Firefox 69.0 (x64 en-US)
      20170112     1.2.9.112       Greenshot 1.2.9.112             
      2.1.5           VLC media player  

      .NOTES
      Place additional notes here.

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.Tools


      .OUTPUTS
      To the screen until the File parameter is working

  #>

  [cmdletbinding(DefaultParameterSetName = 'SortList',SupportsPaging = $true)]
  Param(
    
    [Parameter(Mandatory = $true,HelpMessage = 'At least part of the software name to test', Position = 0,ParameterSetName = 'SoftwareName')]
    [String[]]$SoftwareName,
    [Parameter(ParameterSetName = 'SortList')]
    [Parameter(ParameterSetName = 'SoftwareName')]
    [ValidateSet('DateInstalled', 'DisplayName','DisplayVersion')] 
    [String]$SortList = 'DateInstalled'
    
  )
  
  Begin { 
    $SoftwareOutput = @()
    $InstalledSoftware = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*)
  }
  
  Process {
    Try 
    {
      if($SoftwareName -eq $null) 
      {
        $SoftwareOutput = $InstalledSoftware |
        #Sort-Object -Descending -Property $SortList |
        Select-Object -Property @{
          Name = 'DateInstalled'
          Exp  = {
            $_.InstallDate
          }
        }, @{
          Name = 'Version'
          Exp  = {
            $_.DisplayVersion
          }
        }, DisplayName #, UninstallString 
      }
      Else 
      {
        foreach($Item in $SoftwareName)
        {
          $SoftwareOutput += $InstalledSoftware |
          Where-Object -Property DisplayName -Match -Value $SoftwareName|
          Select-Object -Property @{
            Name = 'DateInstalled'
            Exp  = {
              $_.InstallDate
            }
          }, @{
            Name = 'Version'
            Exp  = {
              $_.DisplayVersion
            }
          }, DisplayName #, UninstallString 
        }
      }
    }
    Catch 
    {
      # get error record
      [Management.Automation.ErrorRecord]$e = $_

      # retrieve information about runtime error
      $info = New-Object -TypeName PSObject -Property @{
        Exception = $e.Exception.Message
        Reason    = $e.CategoryInfo.Reason
        Target    = $e.CategoryInfo.TargetName
        Script    = $e.InvocationInfo.ScriptName
        Line      = $e.InvocationInfo.ScriptLineNumber
        Column    = $e.InvocationInfo.OffsetInLine
      }
      
      # output information. Post-process collected info, and log info (optional)
      $info
    }
  }
  
  End{ 
    Switch ($SortList){
      'DisplayName' 
      {
        $SoftwareOutput |
        Sort-Object -Property 'displayname'
      }
      'DisplayVersion' 
      {
        $SoftwareOutput |
        Sort-Object -Property 'Version'
      }
      'UninstallString'
      {

      }
      'DateInstalled'  
      {
        $SoftwareOutput |
        Sort-Object -Property 'DateInstalled' 
      } 
      default  
      {
        $SoftwareOutput |
        Sort-Object -Property 'DateInstalled'
      } #'InstallDate'
      
    }
  }
}

function Get-SystemUpTime
{
  <#PSScriptInfo

      .VERSION 1.7

      .GUID 4f5d3d64-7d6e-407e-a902-cdbc1b6175cd

      .AUTHOR Erik

      .COMPANYNAME KnarrStudio

      .COPYRIGHT

      .TAGS

      .LICENSEURI

      .PROJECTURI https://knarrstudio.github.io/ITPS.OMCS.Tools/

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES 

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES


      .PRIVATEDATA

  #>

  <# 
      .SYNOPSIS
      Returns the last boot time and uptime in hours for one or many computers
    
      .DESCRIPTION 
      Returns system uptime
    
      .PARAMETER ComputerName
      One or Many Computers
    
      .PARAMETER ShowOfflineComputers
      Returns a list of the computers that did not respond.
    
      .EXAMPLE
      Get-UpTime -ComputerName Value -ShowOfflineComputers
      Returns the last boot time and uptime in hours of the list of computers in "value" and lists the computers that did not respond
    
      .OUTPUTS
      ComputerName LastBoot           TotalHours       
      ------------ --------           ----------       
      localhost    10/9/2019 00:09:28 407.57           
      tester       Unable to Connect  Error Shown Below
    
      Errors for Computers not able to connect.
      tester Error: The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
  #>
  
  [cmdletbinding(DefaultParameterSetName = 'DisplayOnly')]
  Param (
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$ShowOfflineComputers,
    <# [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$DisplayOnly,#>
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$BootOnly,
    [Parameter (ParameterSetName = 'FileOnly')]
    [Switch]$FileOnly,
    [Parameter (ParameterSetName = 'FileOnly')]
    [String]$OutCsv = "$env:HOMEDRIVE\Temp\UpTime.csv"
  )
  
  BEGIN {
    $ErroredComputers = @()
    if($BootOnly)
    {
      $SelectObjects = 'ComputerName', 'LastBoot'
    }
    else
    {
      $SelectObjects = 'ComputerName', 'LastBoot', 'TotalHours'
    }
    if($DisplayOnly)
    {
      $OutCsv = $null
    }
    if($FileOnly)
    {
      if (Test-Path -Path $OutCsv)
      {
        $i = 1
        $NewFileName = $OutCsv.Trim('.csv')
        Do 
        {
          $OutCsv = ('{0}({1}).csv' -f $NewFileName, $i)
          $i++
        }while (Test-Path -Path $OutCsv)
      }
    }
  }
  
  PROCESS {
    Foreach ($Computer in $ComputerName) 
    {
      Try 
      {
        $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
        $UpTime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
        $Properties = @{
          ComputerName = $Computer
          LastBoot     = $OS.ConvertToDateTime($OS.LastBootUpTime)
          TotalHours   = ( '{0:n2}' -f $UpTime.TotalHours)
        }
        
        $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property $SelectObjects
      }
      catch 
      {
        if ($ShowOfflineComputers) 
        {
          $ErrorMessage = ('{0} Error: {1}' -f $Computer, $_.Exception.Message)
          $ErroredComputers += $ErrorMessage
          
          $Properties = @{
            ComputerName = $Computer
            LastBoot     = 'Unable to Connect'
            TotalHours   = 'Error Shown Below'
          }
          
          $Object = New-Object -TypeName PSObject -Property $Properties | Select-Object -Property $SelectObjects
        }
      }
      finally 
      {
        if($FileOnly)
        {
          $Object | Export-Csv -Path $OutCsv -Append -NoTypeInformation
          Write-Verbose -Message ('Output located {0}' -f $OutCsv)
        }
        
        Write-Output -InputObject $Object
        
        $Object       = $null
        $OS           = $null
        $UpTime       = $null
        $ErrorMessage = $null
        $Properties   = $null
      }
    }
  }
  
  END {
    if ($ShowOfflineComputers) 
    {
      Write-Output -InputObject ''
      Write-Output -InputObject 'Errors for Computers not able to connect.'
      Write-Output -InputObject $ErroredComputers
    }
  }
}
