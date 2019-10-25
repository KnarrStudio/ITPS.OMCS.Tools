Function Get-InstalledSoftware
{
  <#
      .SYNOPSIS
      "Get-InstalledSoftware" collects all the software listed in the Uninstall registry.

      .PARAMETER SortList
      This will provide a list of installed software from the registry.

      .PARAMETER SoftwareName
      This wil provide the installed date, version, and name of the software in the "value".

      .PARAMETER File
      Will output to a file, but this is currently now working

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
  #>



  [cmdletbinding(DefaultParameterSetName = 'SortList',SupportsPaging = $true)]
  Param(
    [Parameter(Mandatory,HelpMessage = 'Get list of installed software by installed date or alphabetically', Position = 0,ParameterSetName = 'SortList')]
    [ValidateSet('InstallDate', 'DisplayName')] [Object]$SortList,
    
    [Parameter(Mandatory = $true,HelpMessage = 'At least part of the software name to test', Position = 0,ParameterSetName = 'SoftwareName')]
    [String[]]$SoftwareName,
    [Parameter(Mandatory = $false,HelpMessage = 'At least part of the software name to test', Position = 1,ParameterSetName = 'SoftwareName')]
    [Parameter(ParameterSetName = 'SortList')]
    [Switch]$File
 
  )
  
  Begin{ }
  
  Process {
    Try 
    {
      $InstalledSoftware = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*)
      if($SortList) 
      {
        $InstalledSoftware |
        Sort-Object -Descending -Property $SortList |
        Select-Object -Property @{Name='Date Installed';Exp={$_.Installdate}},@{Name='Version';Exp={$_.DisplayVersion}}, DisplayName #, UninstallString 
      }
      Else 
      {
        foreach($Item in $SoftwareName)
        {
          $InstalledSoftware |
          Where-Object -Property DisplayName -Match -Value $Item |
          Select-Object -Property @{Name='Version';Exp={$_.DisplayVersion}}, DisplayName
        }
      }
    }
    Catch 
    {
      # get error record
      [Management.Automation.ErrorRecord]$e = $_

      # retrieve information about runtime error
      $info = [PSCustomObject]@{
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
  
  End{ }
}