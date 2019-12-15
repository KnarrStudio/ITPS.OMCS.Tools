function Test-Replication
{
  <#
      .SYNOPSIS
      Perform a user based test to ensure Replication is working.  You must know at least two of the replication partners

      .DESCRIPTION
      Perform a user based test to ensure Replication is working.  You must know at least two of the replication partners

      .PARAMETER FilePath
      Name of the file to test.  Format as a txt file with starting with the '\'

      .PARAMETER DfsrServers
      Two or more of the replication partner's Net Bios Name

      .PARAMETER test
      Changes sleep time to 1 second.  

      .EXAMPLE
      .EXAMPLE
      Test-Replication -DfsrServers Server1, Server2, Server3 -FilePath  \folder-1\test-date.txt
    
      Name              Value
      ----              -----
      Server1           12/14/2019 11:06:29 - Good
      Server3           12/14/2019 11:06:29 - File Missing
      Server2           12/14/2019 11:06:30 - Failed

      Good: The file has been replicated 
      Failed: The file has not replicated 
      File Missing: is just that

      The file contents will look like:
      12/15/2019 10:01:00 - MyUserName Tested replication of this file from  Workstation1
      12/15/2019 10:03:48 - MyUserName Tested replication of this file from  Workstation1

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Test-Replication

      .INPUTS
      List of Server names and file path

      .OUTPUTS
      Screen and file
  #>

  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory ,HelpMessage = 'Enter a file and path name.  Example "\Sharename\Filename.log"')]
    #Reserve for PS ver 6 -     [ValidatePattern('(\\[a-zA-Z0-9\-_]{1,}){1,}[\$]{0,1}',ErrorMessage = 'The pattern needs to be \Sharename\Filename')]
    [ValidatePattern('(\\[a-zA-Z0-9\-_]{1,}){1,}[\$]{0,1}')]
    [String]$FilePath,
    [Parameter(Mandatory,HelpMessage = 'DFSR path to test files separated by comma', Position = 0)]
    [ValidateCount(2,5)]
    [String[]]$DfsrServers,
    [Switch]$test
  )
   
  $Results = [ordered]@{}
  $FirstDfsrServer = $DfsrServers[0]
  $TestFilePath = ('\\{0}{1}' -f $FirstDfsrServer, $FilePath)   
  
  if(-not $test)
  {
    $time = 5
    $instructions = "`n Good: The file has been replicated `n Failed: The file has not replicated `n File Missing: is just that"
  }
  else
  {
    $time = 1
    $instructions = 'TEST MODE'
  }
 
  
  function Get-TimeStamp 
  {
    $(Get-Date -Format G)
  }
  Write-Debug -Message ('Time: {0}' -f $time)
  
  $DateTime = Get-Date -Format G
  Write-Debug -Message ('Date Time: {0}' -f $DateTime)
  
  $DateTimeUserStamp = ('{0} - {1} Tested replication of this file from {2}' -f $DateTime, $env:username, $env:COMPUTERNAME)
  Write-Debug -Message ('Date Time User Stamp: {0}' -f $DateTimeUserStamp)
  
  #$DateTimeUserStamp = ('{0} - {1}' -f $DateTime, $env:username)
  $DateTimeUserStamp | Out-File -FilePath $TestFilePath  -Append

  #Only for Testing.  Comment ou for real script
  #Copy-Item -Path '.\Server-1\test-date.txt' -Destination '.\Server-2\test-date.txt'
  
  foreach($Server in $DfsrServers)
  {
    Write-Debug -Message ('Server:  {0}' -f $Server)
    Write-Debug -Message ('File path: {0}' -f $FilePath)

    $ServerShareFile = ('\\{0}{1}' -f $Server, $FilePath)
    Write-Debug -Message ('Server Share File: {0}' -f $ServerShareFile)

    If(Test-Path -Path $ServerShareFile)
    {
      #Sleep to give the file time to replicate
      Start-Sleep -Seconds $time

      if($(Get-Content -Path $ServerShareFile  | Select-String -Pattern $DateTimeUserStamp))
      {
        $TimeStamp = Get-TimeStamp
        $Results.Add($Server,$(('{0} - Good' -f $TimeStamp)))
      }
      else
      {
        Start-Sleep -Seconds $time*2

        if($(Get-Content -Path $ServerShareFile  | Select-String -Pattern $DateTimeUserStamp))
        {
          $TimeStamp = Get-TimeStamp
          $Results.Add($Server,$(('{0} - Good' -f $TimeStamp)))
        }
        else
        {
          $TimeStamp = Get-TimeStamp
          $Results.Add($Server,$(('{0} - Failed' -f $TimeStamp)))
        }
      }
    }
    Else 
    {
      $TimeStamp = Get-TimeStamp
      $Results.Add($Server,$(('{0} - File Missing' -f $TimeStamp)))
    }
  }

  $Results
  Write-Output -InputObject ('{0}' -f $instructions )
}


#Test-Replication -DfsrServers 'Localhost', '$env:computername' -FilePath \folder-1\test-date.txt


# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYRPFiXt2Ya0LQh9wNSoz40JK
# 56SgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
# MBYxFDASBgNVBAMTC0VyaWtBcm5lc2VuMB4XDTE3MTIyOTA1MDU1NVoXDTM5MTIz
# MTIzNTk1OVowFjEUMBIGA1UEAxMLRXJpa0FybmVzZW4wgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBAKYEBA0nxXibNWtrLb8GZ/mDFF6I7tG4am2hs2Z7NHYcJPwY
# CxCw5v9xTbCiiVcPvpBl7Vr4I2eR/ZF5GN88XzJNAeELbJHJdfcCvhgNLK/F4DFp
# kvf2qUb6l/ayLvpBBg6lcFskhKG1vbEz+uNrg4se8pxecJ24Ln3IrxfR2o+BAgMB
# AAGjYDBeMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEcGA1UdAQRAMD6AEMry1NzZravR
# UsYVhyFVVoyhGDAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlboIQyWSKL3Rtw7JMh5kR
# I2JlijAJBgUrDgMCHQUAA4GBAF9beeNarhSMJBRL5idYsFZCvMNeLpr3n9fjauAC
# CDB6C+V3PQOvHXXxUqYmzZpkOPpu38TCZvBuBUchvqKRmhKARANLQt0gKBo8nf4b
# OXpOjdXnLeI2t8SSFRltmhw8TiZEpZR1lCq9123A3LDFN94g7I7DYxY1Kp5FCBds
# fJ/uMYIBSjCCAUYCAQEwKjAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlbgIQyWSKL3Rt
# w7JMh5kRI2JlijAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU1X89O77GUVdCq34fJqXbXHphvpww
# DQYJKoZIhvcNAQEBBQAEgYBS12uEKDerCZuG7BTPq2TJSsyjGPby6YbL4wI0XryK
# Vyzinmakk66D8Ivz0aoeTcvcaarjLqgTbV+06D5D9JzhJDVXzdhAi7xMXqWvSogD
# irHM/3UEs4xJV57vqb2z1na3r2sD2W9Oj/bxPoeS0BtMU/xPeGhcUG9jHdX2Dgue
# qQ==
# SIG # End signature block
