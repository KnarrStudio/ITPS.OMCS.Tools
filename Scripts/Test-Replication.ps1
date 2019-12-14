function Test-Replication
{
  <#
      .SYNOPSIS
      Perform a user based test to ensure Replication is working.  You must know at least two of the replication partners

      .DESCRIPTION
      Perform a user based test to ensure Replication is working.  You must know at least two of the replication partners

      .PARAMETER DfsrServers
      Two or more of the replication partner's Net Bios Name

      .PARAMETER TestFile
      Name of the file to test.  Format as a txt file with starting with the '\'

      .EXAMPLE
      Test-Replication -DfsrServers Server1, Server2, Server3 -TestFile \folder-1\test-date.txt
    
      Name                           Value                                                                                      
      ----                           -----                                                                                      
      Server1                       12/14/2019 11:06:29 - Good                                                                 
      Server3                       12/14/2019 11:06:29 - File Missing                                                         
      Server2                       12/14/2019 11:06:30 - Failed                                                      

      Good: The file has been replicated 
      Failed: The file has not replicated 
      File Missing: is just that

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Test-Replication

      .INPUTS
      List of Server names a

      .OUTPUTS
      List of output types produced by this function.
  #>


  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory,HelpMessage = 'DFSR path to test files separated by comma', Position = 0)]
    [ValidateCount(2,5)]
    [String[]]$DfsrServers,
    [Parameter(Mandatory ,HelpMessage = 'Enter a filename with parent folder ex. "\folder-1\test-date.txt"')]
    [ValidatePattern({
          \\*\\*.txt
    })]
    [String]$TestFile #= '\folder-1\test-date.txt'
  )

  $FirstDfsrServer = $DfsrServers[0] 
  
  $results = [ordered]@{}
  $instructions = "`n Good: The file has been replicated `n Failed: The file has not replicated `n File Missing: is just that"
  
  function Get-TdStamp 
  {
    #Possible future use
  }
  
  $DateTime = Get-Date -Format G
  $DateTimeUserStamp = ('{0} - {1} Tested replication of this file from the computer {2}' -f $DateTime, $env:username, $env:COMPUTERNAME)
  $DateTimeUserStamp | Out-File -FilePath ('\\{0}{1}' -f $FirstDfsrServer, $TestFile) -Append

  #Only for Testing.  Comment ou for real script
  #Copy-Item -Path '.\Server-1\test-date.txt' -Destination '.\Server-2\test-date.txt'
  
  foreach($Server in $DfsrServers)
  {
    $ServerShareFile = ('\\{0}{1}' -f $Server, $TestFile)

    If(Test-Path -Path $ServerShareFile)
    {
      #Sleep to give the file time to replicate
      Start-Sleep -Seconds 3

      if($(Get-Content -Path $ServerShareFile  | Select-String -Pattern $DateTimeUserStamp))
      {
        $results.Add($Server,$("$(Get-Date -Format G) - Good"))
      }
      else
      {
        Start-Sleep -Seconds 10

        if($(Get-Content -Path $ServerShareFile  | Select-String -Pattern $DateTimeUserStamp))
        {
          $results.Add($Server,$("$(Get-Date -Format G) - Good"))
        }
        else
        {
          $results.Add($Server,$("$(Get-Date -Format G) - Failed"))
        }
      }
    }
    Else 
    {
      $results.Add($Server,$("$(Get-Date -Format G) - File Missing"))
    }
  }

  $results
  Start-Sleep -Seconds 1
  Write-Output -InputObject ('{0}' -f $instructions )
}

#Test-Replication -DfsrServers Lenova-11, Server2 -TestFile \folder-1\test-date.txt



# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzOGuc2Sg8aid5P8vmAYbwNFE
# ziugggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU3x6efl/os/GpWTZgI3dLSZH0fh8w
# DQYJKoZIhvcNAQEBBQAEgYCCO8HxFkQl4cUppEDUDZ4cvpVUJFwGGwYDqTGkD41u
# VVQ4COGoJ5tl91NhWMBRZ08/nZEN9GOAevKbIY5n5Gl1wPU6zV06CeVZfSHvF+nF
# 6zRIi5NkIvgQEceAKcsvoyU1gktj4LDGs9SyQSp9BP3RZKHWkKg9CeMjEG34IL5f
# ZA==
# SIG # End signature block
