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
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAL8+vlr670HmZJQc2nUIzlZM
# Th6gggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU52OQEPfNZdqwUwieovNCAmVmVAMw
# DQYJKoZIhvcNAQEBBQAEgYAx2KGaVFz9s5rHRxBq1YtUUFjKf8IzpfulAtCoHVt3
# 2MxA8pAvTVFmamXv5MnpkrUnmz4Ufrv4neJNJdW4lNGVlK3ofwjBpssk8wCXSXon
# wcJCEoZWTPUdQOOqkDGxkJ2hTucSdt8Ma27clU/Lnr7HW2jhRn11NntUv3MYfm0C
# mQ==
# SIG # End signature block
