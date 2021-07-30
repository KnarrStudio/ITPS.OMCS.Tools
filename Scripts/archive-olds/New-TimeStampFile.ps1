#requires -Version 1.0

function New-TimeStampFile 
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

      .PARAMETER FilePath
      where to put the file, if "create" is added.
      To create the file add -FilePath.  -Use the create parameter for this.

      .PARAMETER Create
      This will create the file, otherwise the filename only will be returned.

      .PARAMETER NoClober
      If this is sent, then the file name will not overwrite an existing file, but add a (X) to the end of the file name, where X is a number
      
      .EXAMPLE
      New-TimeStampFile -baseNAME Value -FileType Value -StampFormat Value -FilePath Value
      Actually creates the file in the folder specified in the -FilePath parameter

      .PARAMETER StampFormat
      StampFormat is an integer from 1-4 which selects the date foramat.  For more information "Get-Help New-TimeStampFile -full" .

      .EXAMPLE
      New-TimeStampFileName -baseNAME TestFile -FileType log -StampFormat 1
      This creates a file TestFile-1910260715.log

      .EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 2 -Create -NoClober
      This creates a file TestFile-20191026.log if it does not exist
      This creates a file TestFile-20191026(1).log if the original does exist


      .EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 3
      This creates a file TestFile-299071531.log

      .EXAMPLE
      New-TimedStampFileName -baseNAME TestFile -FileType log -StampFormat 4 -Create
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
      If the "create" switch is selected, then the file will be created.
  #>

  param
  (
    [Parameter(Mandatory = $true,HelpMessage = 'Prefix of file or log name')]
    [String]$baseNAME,
    [Parameter(Mandatory = $true,HelpMessage = 'Extention of file.  txt, csv, log')]
    [alias('Extension')]
    [String]$FileType,
    [Parameter(HelpMessage = 'Formatting Choice 1 to 4')]
    [ValidateRange(1,4)]
    [AllowNull()]
    [int]$StampFormat,
    [Switch]$Create,
    [Parameter(ValueFromPipeline = $true,HelpMessage = 'File Path')]
    [AllowNull()]
    [String]$FilePath,
    [Switch]$NoClobber
    
  )
  
  
  if (-not $FilePath)
  {
    $FilePath = Get-Location
  }
  
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
      $DateStamp = Get-Date -Format o | ForEach-Object -Process {
        $_ -replace ':', '.'
      }
      # 2019-09-02T14:09:02.1593508-04:00
    } 
    default
    {
      Write-Verbose -Message 'No time format selected'
    }
  }

  if ($StampFormat)
  {
    $FullFileName = ('{0}-{1}.{2}' -f $baseNAME, $DateStamp, $FileType)
  }
  else
  {
    $FullFileName = ('{0}.{1}' -f $baseNAME, $FileType)
  }

  If ($Create)
  {
    if(Test-Path -Path $FullFileName)
    {
      if ($NoClobber)
      {
        $i = 0

        if (-not (Test-Path -Path $FullFileName))
        {
          New-Item -Path $FullFileName -ItemType File
        }
        else
        {
          $baseNAME = $($FullFileName.Split('.'))[0]
          $FileType = $($FullFileName.Split('.'))[1]
 
          while (Test-Path -Path ('{0}.{1}' -f $baseNAME, $FileType))
          {
            $i++
            $baseNAME = $($baseNAME.Split('(')[0]+"($i)")
          }
          $FullFileName = ('{0}.{1}' -f $baseNAME, $FileType)
          $null = New-Item -Path $FullFileName -ItemType File
        }
      }
      else
      {
        $null = New-Item -Path $FullFileName -ItemType File -Force
      }
    }
    else
    {
      #Test path
      If(-not (Test-Path -Path $FilePath))
      {
        $null = New-Item -Path $FilePath -ItemType Directory -Force
      }
      $null = New-Item -Path ('{0}\{1}' -f $FilePath, $FullFileName) -ItemType File -Force
    }
  }
  else
  {
    Return $FullFileName
  }
}


<#
BaseName          : mytest-20210603
Target            : {}
LinkType          : 
Name              : mytest-20210603.txt
Length            : 0
DirectoryName     : C:\Users\erika\testfile
Directory         : C:\Users\erika\testfile
IsReadOnly        : False
Exists            : True
FullName          : C:\Users\erika\testfile\mytest-20210603.txt
Extension         : .txt
#>
