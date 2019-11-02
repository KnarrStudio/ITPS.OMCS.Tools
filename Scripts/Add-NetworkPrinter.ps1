#requires -Version 3.0 -Modules PrintManagement
function Add-NetworkPrinter
{
  <#
      .SYNOPSIS
      Retrieves all of the printers you are allowed to see on a print server that you designate.  
      Allows you to select it and adds the printer to your local workstation.

      .PARAMETER PrintServer
      Name of the print server you will using.

      .PARAMETER Location
      The location as indicated on the printer properties

      .EXAMPLE
      Add-NetworkPrinter -PrintServer Value -Location Value
      Finds all of the printers with the location set to the value indicated.

      .OUTPUTS
      Connection to a networked printer
  #>
  
  
  [cmdletbinding()]
  param
  (
    [Parameter(Mandatory,HelpMessage = 'Enter the printserver name',Position=0)]
    [String]$PrintServer,
    [Parameter(Position=1)]
    [AllowNull()]
    [String]$Location

  )

  try
  {
    if(!(Get-Module -Name PrintManagement))
    {
      Write-Verbose -Message 'Importing Print Management Module'
      Import-Module -Name PrintManagement
    }
    Write-Verbose -Message 'Print Management Module Imported'
    if(Test-Connection -ComputerName $PrintServer -Count 1 -Quiet)
    {
      if($Location)
      {
        $PrinterSelection = Get-Printer -ComputerName $PrintServer |
        Select-Object -Property Name, Location, DriverName, PortName |
        Where-Object{$_.location -match $Location} |
        Out-GridView -PassThru -Title 'Printer Select-O-Matic!' -ErrorAction Stop
        Write-Verbose -Message ('Printer Selected {0}' -f $PrinterSelection)
      }
      else
      {
        $PrinterSelection = Get-Printer -ComputerName $PrintServer |
        Select-Object -Property Name, DriverName, PortName | 
        Out-GridView -PassThru -Title 'Printer Select-O-Matic!' -ErrorAction Stop
        Write-Verbose -Message ('Printer Selected {0}' -f $PrinterSelection)
      }
      $PrinterName = $PrinterSelection.name
      Write-Verbose -Message ('Printer Name {0}' -f $PrinterName)
   
      #$PrintServer # = 'test'
      Add-Printer -ConnectionName ('\\{0}\{1}' -f $PrintServer, $PrinterName) -ErrorAction Stop
      Write-Verbose -Message ('Printer Connected \\{0}\{1}' -f $PrintServer, $PrinterName)
    }
    else
    {
      Write-Warning -Message ('Unable to connect to {0}.' -f $PrintServer)
    }
 

    #Add-NetworkPrinter -PrintServer ServerName
  }
  # NOTE: When you use a SPECIFIC catch block, exceptions thrown by -ErrorAction Stop MAY LACK
  # some InvocationInfo details such as ScriptLineNumber.
  # REMEDY: If that affects you, remove the SPECIFIC exception type [Microsoft.Management.Infrastructure.CimException] in the code below
  # and use ONE generic catch block instead. Such a catch block then handles ALL error types, so you would need to
  # add the logic to handle different error types differently by yourself.
  catch [Microsoft.Management.Infrastructure.CimException]
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



# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEO1zDW323M5/Q75ZiJ8UatOy
# hTKgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUd1XY/Z/c2B5tiR+cSXNWuiDgDZMw
# DQYJKoZIhvcNAQEBBQAEgYBfEEu3FTdIAQslvy08kTsYGhK1JMdwpbbJd6/POoTo
# ebHHGjm6gnK9XPAX0E1RVfYQ9fxat+Oq9aAIoAMn+hc1f9p9deOxgmJFdcdXpAOQ
# DT42Ewi4inNaxU3RHQ519KzemGNvDDxjjnYMRtHJHWmcPNh6pREgxIagmJVRQ5c6
# eA==
# SIG # End signature block
