﻿function New-TimeStampFile 
{
  <#
      .SYNOPSIS
      Creates a file or filename with a time stamp in the name

      .DESCRIPTION
      Allows you to create a  file or filename with a time stamp.  You provide the base name, extension, date format and it should do the rest. It should be setup to be a plug-n-play function that can be used in or out of another script.
    
      .PARAMETER baseNAME
      This is the primary name of the file.  It will be followed by the date/time stamp.

      .PARAMETER FileType
      The extension. ig. csv, txt, log

     .PARAMETER ReportFolder
      To acutally create the file add -ReportFolder.

    .EXAMPLE
    New-TimeStampFile -baseNAME Value -FileType Value -StampFormat Value -ReportFolder Value
    Actually creates the file in the folder specified in the -ReportFolder parameter

      .PARAMETER StampFormat
      StampFormat is an integer from 1-4 which selects the date foramat.  For more information "Get-Help New-TimeStampFile -full" .

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
    [Parameter(Mandatory=$false,HelpMessage = 'Extention of file.  txt, csv, log')]
    [alias('Extension')]
    [String]$FileType= 'log',
    [Parameter(Mandatory,HelpMessage = 'Formatting Choice 1 to 4')]
    [ValidateRange(1,4)]
    [int]$StampFormat,
    [Parameter(ValueFromPipeline,HelpMessage = 'Folder Path')]
    [AllowNull()]
    [String]$ReportFolder
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

  $FileName = ('{0}-{1}.{2}' -f $baseNAME,$DateStamp,$FileType)
  

    If ($ReportFolder){
      If(-not (Test-Path -Path $ReportFolder))
      {
        $null = New-Item -Path $ReportFolder -ItemType Directory -Force
        }
        $null = New-Item -Path ('{0}\{1}' -f $ReportFolder, $FileName) -ItemType File -Force
    Return ('{0}\{1}' -f $ReportFolder, $FileName)
      }
    else
    {
      Return $FileName
    }
}



