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
    [ValidateSet('InstallDate', 'DisplayName','DisplayVersion')] 
    [String]$SortList = 'InstallDate'
    
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
          Name = 'Date Installed'
          Exp  = {
            $_.Installdate
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
          Where-Object -Property DisplayName -Match -Value $Item |
          Select-Object -Property @{
            Name = 'Version'
            Exp  = {
              $_.DisplayVersion
            }
          }, DisplayName # , UninstallString 
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
        Sort-Object -Property displayname
      }
      'DisplayVersion' 
      {
        $SoftwareOutput |
        Sort-Object -Property 'Version'
      }
      'UninstallString'
      {

      }
      default  
      {
        $SoftwareOutput |
        Sort-Object -Property 'Date Installed'
      } #'InstallDate'
      
    }
  }
}

#
# Get-InstalledSoftware -SortList InstallDate | select -First 10 #| Format-Table -AutoSize
# Get-InstalledSoftware -SoftwareName 'Mozilla Firefox',vlc, Acrobat
# Get-InstalledSoftware
 

# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/0DlqtO3Ha4bduESR+vsY9oZ
# j1KgggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU6CvzDSrj
# WPtyFWgZpedLiQbUHcYwDQYJKoZIhvcNAQEBBQAEgYAyHKKgFJIhsikAZRWRkHZi
# KzZUJTVtaYgwZvyvN9zK0W1d3wKYwa9snk1OWIIcDbQSWcmR01untw0tt4ekZqVk
# aV//3xPiucQwRN3GM2kRVLY5bLZ87Qq58FGJXyOrsIptMOaBlG4n2lAmpW+y4utK
# 6ycN1BDCwGe333Pb1HOg0Q==
# SIG # End signature block
