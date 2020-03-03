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
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHcu9/06llA53921oDRvi91SA
# BUSgggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUtBRgGUrh
# 1C+P8PhaKi8o0fVzpw8wDQYJKoZIhvcNAQEBBQAEgYB4vqt25KXDALU+Ol3/IoxU
# WPKdthtE61w4ANGPIYAD+ZGSV/YFYgW1IrWMGVPxANqzHmmozjxV544GwL6w4ly7
# MMsa81HJeyXWTndKlUt4Y5G3106b7NU6UhpEhHoIAjeoYTtxu3SiR2afXFnWIuFC
# QIwKg4esxvAWoDs0zaIAvA==
# SIG # End signature block
