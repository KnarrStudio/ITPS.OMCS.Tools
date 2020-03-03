function New-TimeStampFileName 
{
  <#
      .SYNOPSIS
      Creates a filename where a time stamp in the name is needed

      .DESCRIPTION
      Allows you to create a filename with a time stamp.  You provide the base name, extension, date format and it should do the rest. It should be setup to be a plug-n-play function that can be used in or out of another script.
    
      .PARAMETER baseNAME
      This is the primary name of the file.  It will be followed by the date/time stamp.

      .PARAMETER FileType
      The extension. ig. csv, txt, log

      .PARAMETER StampFormat
      Describe parameter -StampFormat.

      .EXAMPLE
      New-TimeStampFileName -baseNAME TestFile -FileType log -StampFormat 1
      This creates a file TestFile-1910260715.log

.EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 2
      This creates a file TestFile-20191026.log

.EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 3
      This creates a file TestFile-299071531.log

     .EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 4
      This creates a file TestFile-2019-10-26T07.16.33.3394199-04.00.log

      .NOTES
      StampFormats:
      (1) YYMMDDHHmm  (Two digit year followed by two digit month day hours minutes.  This is good for the report that runs more than once a day)  -example 1703162145
      
      (2) YYYYMMDD  (Four digit year two digit month day.  This is for the once a day report)  -example 20170316 
      
      (3) jjjHHmmss (Julian day then hours minutes seconds.  Use this when you are testing, troubleshooting or creating.  You won't have to worry about overwrite or append errors)  -example 160214855 
      
      (4) YYYY-MM-DDTHH.mm.ss.ms-UTC (Four digit year two digit month and day "T" starts the time section two digit hour minute seconds then milliseconds finish with an hours from UTC -example 2019-04-24T07:23:51.3195398-04:00
      
      Old #4: YY/MM/DD_HH.mm  (Two digit year/month/day _ Hours:Minutes.  This can only be used inside a log file)  -example 17/03/16_21:52

      .INPUTS
      Any authorized file name for the base and an extension that has some value to you.

      .OUTPUTS
      example output - Filename-20181005.bat
  #>

  param
  (
    [Parameter(Mandatory,HelpMessage = 'Prefix of file or log name')]
    [String]$baseNAME,
    [Parameter(Mandatory,HelpMessage = 'Extention of file.  txt, csv, log')]
    [alias('Extension')]
    [String]$FileType,
    [Parameter(Mandatory,HelpMessage = 'Formatting Choice 1 to 4')]
    [ValidateRange(1,4)]
    [int]$StampFormat
  )

  switch ($StampFormat){
    1 
    {
      $DateStamp = Get-Date -UFormat '%y%m%d%H%M'
    } # 1703162145 YYMMDDHHmm
    2
    {
      $DateStamp = Get-Date -UFormat '%Y%m%d'
    } # 20170316 YYYYMMDD
    3
    {
      $DateStamp = Get-Date -UFormat '%j%H%M%S'
    } # 160214855 jjjHHmmss
    4
    {
      $DateStamp = Get-Date -Format o | ForEach-Object -Process {$_ -replace ':', '.'}
      # 2019-09-02T14:09:02.1593508-04:00

    } 
    default
    {
      Write-Verbose -Message 'No time format selected'
    }
  }

  ('{0}-{1}-{2}' -f $baseNAME,$DateStamp,$FileType)
}



# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8FTCgOcHfceeknEDQeVTfqgb
# i7+gggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUNa5E7StW
# GamlJ9MklynW9C5PJdkwDQYJKoZIhvcNAQEBBQAEgYBywCRCdTJAIw8XkWxiJ3fu
# 8+4mMTmgdH4szpBXBPTyZPEJYMGNVtGa9pDUy+HImRU0xy9Eu7G/ktFRekt2jkO8
# 8kaVaSNa2Lg54TNxq4Zoa7UOuJ2JMalRxYocjtBCtkSQYXq6eyI72RNjWY9xV9cs
# LgUmIIz7O7t5kJOZwQXadw==
# SIG # End signature block
