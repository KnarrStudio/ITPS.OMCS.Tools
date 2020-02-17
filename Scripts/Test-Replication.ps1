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
      Test is a switch that is used for testing the script locally.  Will be removed in the future.

      .EXAMPLE
      Test-Replication -DfsrServers Server1, Server2, Server3 -FilePath  \folder-1\test-date.txt
    
      DFSR Replication Test

      Server1 
      Status: Good 
      Message Replicated: 2/17/2020 08:16:06 - MyUserName Tested replication of this file from Workstation-11
      File Path: \\Server1\Folder-1\test-date.txt

      Server2 
      Status: Failed 
      Message Replicated: 2/17/2020 08:16:06 - MyUserName Tested replication of this file from Workstation-11
      File Path: \\Server2\Folder-1\test-date.txt

      Server3 
      Status: File Missing 
      Message Replicated: 2/17/2020 08:16:06 - MyUserName Tested replication of this file from Workstation-11
      File Path: \\Server3\Folder-1\test-date.txt


      Good: The file has been replicated
      Failed: The file has not replicated
      File Missing: is just that

      The file contents will look like:
      12/15/2019 10:01:00 - MyUserName Tested replication of this file from  Workstation-11
      12/15/2019 10:03:48 - MyUserName Tested replication of this file from  Workstation-11
      2/17/2020 08:16:06 - MyUserName Tested replication of this file from Workstation-11

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
  
  BEGIN { 
    <#   Testing  
        $DfsrServers = 'Localhost', 'LENOVA-11' 
        $FilePath = '\Folder-1\test-date.txt'
        $Server = 'Localhost'
    Testing  #>

    # Time Delay used for the amount of time to wait for replication to occur
    [int]$TimeDelay = 30
    
    # Getting the first server in the list
    $FirstDfsrServer = $DfsrServers[0]
    
    # Creating the Path
    $TestFilePath = ('\\{0}{1}' -f $FirstDfsrServer, $FilePath)   
    
    # Results storage hash table
    $Results = [ordered]@{}

    # Messages hash table
    $UserMessages = @{
      Msg1        = 'Good: The file has been replicated'
      Msg2        = 'Failed: The file has not replicated'
      Msg3        = 'File Missing: is just that'
      OutputTitle = 'DFSR Replication Test'
    } 

    function Test-ModeNow 
    {
      <#
          .SYNOPSIS
          Test-ModeNow is trigger by the "Test" switch.  It is used for testing the script locally.  Will be removed in the future.
      #>

      $tempfilepath = '.\Folder-2\test-date.txt'
      if($TestFilePath.Length -gt 0)
      {
        #$fileProperty = Get-ItemProperty $TestFilePath | Select-Object -Property *
        $null = Copy-Item -Path $TestFilePath -Destination $tempfilepath
        $null = New-Item -Path $TestFilePath -ItemType File -Force
      }

      $copiedFile = Get-ItemProperty -Path $tempfilepath | Select-Object -Property *
      if($copiedFile.Length -gt 0)
      {
        $null = Copy-Item -Path $tempfilepath -Destination $TestFilePath -Force
      }
    }
    function Get-TimeStamp 
    {
      <#
          .SYNOPSIS
          Time stamp in format - 2/17/2020 10:56:12 
      #>
      Write-Debug -Message 'function Get-TimeStamp'
      $(Get-Date -Format G)
    }

    function Save-Results
    {
      <#
          .SYNOPSIS
          Consolidated Results 
      #>


      param
      (
        [Parameter(Position = 0)]
        [string] $TimeStamp = (Get-TimeStamp),
        [Parameter(Mandatory)]
        [string] $Server,
        [Parameter(Mandatory)]
        [string] $Status,
        [Parameter(Mandatory)]
        [string] $ReplicaStatement,
        [Parameter(Mandatory)]
        [string] $ServerShareFile

      )

      Write-Debug -Message ('function Save-Results - Server: {0}' -f $Server)
      Write-Debug -Message ('function Save-Results - Status: {0}' -f $Status)
      Write-Debug -Message ('function Save-Results - Statement: {0}' -f $ReplicaStatement)
      Write-Debug -Message ('function Save-Results - File Share Path: {0}' -f $ServerShareFile)

      $script:Results = @{}
      $Results.$Server = [ordered]@{}
          
      $Results.Item($Server).Add('Status',$Status)
      $Results.Item($Server).Add('Time',$ReplicaStatement)
      $Results.Item($Server).Add('Path',$ServerShareFile)
    }
  }

  PROCESS {

    Write-Debug -Message ('Time: {0}' -f $TimeDelay)
  
    $TimeStamp = Get-TimeStamp
    Write-Debug -Message ('Date Time: {0}' -f $TimeStamp)
  
    $ReplicaStatement = ('{0} - {1} initiated the replication test of this file from {2}' -f $TimeStamp, $env:username, $env:COMPUTERNAME)
    Write-Debug -Message ('Date Time User Stamp: {0}' -f $ReplicaStatement)
  
    #$ReplicaStatement = ('{0} - {1}' -f $DateTime, $env:username)
    $ReplicaStatement | Out-File -FilePath $TestFilePath  -Append

    #Single host testing
    if ($test)
    {
      Test-ModeNow
    }


    foreach($Server in $DfsrServers)
    {
      $i = 0
      Write-Debug -Message ('foreach Server Loop - Server:  {0}' -f $Server)
      Write-Debug -Message ('foreach Server Loop - File path: {0}' -f $FilePath)
      Write-Debug -Message ('foreach Server Loop - Reset $i to: {0}' -f $i)

      $ServerShareFile = ('\\{0}{1}' -f $Server, $FilePath)
      Write-Debug -Message ('foreach Server Loop - Server Share File: {0}' -f $ServerShareFile)


      If(Test-Path -Path $ServerShareFile)
      {
        $StopTime = (Get-Date).AddSeconds($TimeDelay)
        while($((Get-Date) -le $StopTime)) 
        {
          Write-Progress -Activity ('Testing {0}' -f $FilePath) -PercentComplete ($i / $TimeDelay*100)
          Start-Sleep -Seconds 1
          $i++

          #Single host testing
          if ($test)
          {
            Test-ModeNow
          }

          $FileTest = $(Get-Content -Path $ServerShareFile  | Select-String -Pattern $ReplicaStatement)
          Write-Debug -Message ('File test returns: {0}' -f $FileTest)
        
          If($FileTest)
          {
            break
          }
        }

        if($FileTest)
        {
          $TimeStamp = Get-TimeStamp
          Save-Results -TimeStamp $TimeStamp -Server $Server -Status Good -ReplicaStatement $ReplicaStatement -ServerShareFile $ServerShareFile 
        }
        else
        {
          $TimeStamp = Get-TimeStamp
          Save-Results -TimeStamp $TimeStamp -Server $Server -Status Failed -ReplicaStatement $ReplicaStatement -ServerShareFile $ServerShareFile 
        }
      }
      Else 
      {
        $TimeStamp = Get-TimeStamp
        Save-Results -TimeStamp $TimeStamp -Server $Server -Status 'File Missing' -ReplicaStatement $ReplicaStatement -ServerShareFile $ServerShareFile 
      }
    }
  }
  END {
              
    Write-Output -InputObject ("{1} - {0}`n" -f $UserMessages.OutputTitle, $TimeStamp)
    foreach($DfsrPartner in $Results.Keys)
    {
      $Server = $Results[$DfsrPartner]
      " {0}`n - Status: {1} `n - Replicated Statement: {2}`n - File Path: {3}`n`n" -f $DfsrPartner, $Server.Status, $Server.Time, $Server.Path
    }
    Write-Output -InputObject ("{0}`n{1}`n{2}" -f $UserMessages.Msg1, $UserMessages.Msg2, $UserMessages.Msg3)

  }
}
  
  
  
# Test-Replication -DfsrServers 'Localhost', $env:COMPUTERNAME -FilePath \Folder-1\test-date.txt -test -Debug


# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmFIL35hd5MsuP4LCmXI9X3Fv
# lyOgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUSTjs7wELzc2B9fw0o22QODWbhAww
# DQYJKoZIhvcNAQEBBQAEgYBih38haYrHpkk4BWkkXrjtjePygM85gXZeJ4VCEXdD
# j+GL0IOpSHSOR0Gk5faJ7oWojvzJu8zzHFndJJcX+BaP6vX6ss+LId3oZnVlv1ww
# O4tRn7hSpKAQ2LXNREZ/W3eJjVBPnVWM11sO4aaEa6c7Rx40Dnb6PK66fz+NofTh
# Tw==
# SIG # End signature block
