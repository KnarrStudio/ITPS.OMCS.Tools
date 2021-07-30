#!/usr/bin/env powershell
#requires -Version 3.0 

function Test-AdWorkstationConnections
{
  <#
      .SYNOPSIS
      Pulls a list of computers from AD and then 'pings' them.  

      .DESCRIPTION
      Pulls a list of computers from AD based on the searchbase you pass and stores them in a csv file.  Then it reads the file and 'pings' each name in the file.  If the computer does not respond, it will log it into another csv file report.     

      .PARAMETER ADSearchBase
      Defines where you want to search such as - 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net'

      .PARAMETER WorkstationReportFolder
      This is the folder where you want the output to be stored such as  - '\\server\share\Reports\WorkstationReport' or 'c:\temp'

      .PARAMETER OutputFileName
      The name of the file.  Actually base name of the file.  Passing 'AdDesktop' will result in the following file names - '20191112-1851-AdDesktop_List.csv' and '20191112-1851-AdDesktop_Report.csv'

      .PARAMETER Bombastic
      Is a synonym for verose.  It doesn't quite do verbose, but gives you an output to the screen.  Without it you only the the report.  Does you verbose when running as a job. 

      .EXAMPLE
      Test-AdWorkstationConnections -ADSearchBase Value -WorkstationReportFolder Value -OutputFileName Value -Bombastic
    
      This will give you two files a list and a report. Plus it will give you a count of the computers found and reported with a link the report file.


      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      https://knarrstudio.github.io/ITPS.OMCS.Tools/

      https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .INPUTS
      None other than the parameters

      .OUTPUTS
      The default information in the help file will produce the following:
      \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_Report.csv
      \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_List.csv

      ------------------ Bombasistic Output ----------
      Total workstations found in AD: 32
      Total workstations not responding: 5
      This test was run by myusername from Workstation-1
      You can find the full report at: \\server\share\Reports\WorkstationReport\20191112-1851-AdDesktop_Report.csv

  #>

  [CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact = 'Low')]
  param(

    [Parameter(Mandatory = $false, Position = 1)]
    [String]
    $ADSearchBase = 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net',
    
    [Parameter(Mandatory = $false, Position = 0)]
    [String]
    $WorkstationReportFolder = "$env:temp/Reports/WorkstationReport",

    [Parameter(Mandatory = $false, Position = 2)]
    [string]
    $OutputFileName = 'AdDesktop',
    
    [Switch]$Bombastic
  )
  
  $i = 1
  $BadCount = 0
  $DateNow = Get-Date -UFormat %Y%m%d-%H%M
  $OutputFileNameReport = ('{0}\{1}-{2}_Report.csv' -f $WorkstationReportFolder, $DateNow, $OutputFileName)
  $WorkstationSiteList = ('{0}\{1}-{2}_List.csv' -f $WorkstationReportFolder, $DateNow, $OutputFileName)
  
  
  if(!(Test-Path -Path $WorkstationReportFolder))
  {
    New-Item -Path $WorkstationReportFolder -ItemType Directory
  }
  
  if((Get-Module -Name ActiveDirectory))
  {
    Get-ADComputer -filter * -SearchBase $ADSearchBase -Properties * |
    Select-Object -Property Name, LastLogonDate, Description |
    Sort-Object -Property LastLogonDate -Descending |
    Export-Csv -Path $WorkstationSiteList -NoTypeInformation
  }
  Else
  {
    $OutputFileName = (Get-ChildItem -Path $OutputFileName |
      Sort-Object -Property LastWriteTime |
    Select-Object -Last 1).Name
    $WorkstationSiteList = ('{0}\{1}' -f $WorkstationReportFolder, $OutputFileName)
    Write-Warning -Message ('This is being run using the AD report from {0}' -f $OutputFileName)
  }
  
  $WorkstationList = Import-Csv -Path $WorkstationSiteList -Header Name
  $TotalWorkstations = $WorkstationList.count -1
  
  if($TotalWorkstations -gt 0)
  {
    foreach($OneWorkstation in $WorkstationList)
    {
      $WorkstationName = $OneWorkstation.Name
      if ($WorkstationName -ne 'Name')
      {
        Write-Progress -Activity ('Testing {0}' -f $WorkstationName) -PercentComplete ($i / $TotalWorkstations*100)
        $i++
        $Ping = Test-Connection -ComputerName $WorkstationName -Count 1 -Quiet
        if($Ping -ne 'True')
        {
          $BadCount ++
          $WorkstationProperties = Get-ADComputer -Identity $WorkstationName -Properties * | Select-Object -Property Name, LastLogonDate, Description
          if($BadCount -eq 1)
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileNameReport -NoClobber -NoTypeInformation
          }
          else
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileNameReport -NoTypeInformation -Append
          }
        }
      }
    }
  }
  
  if ($Bombastic)
  {
    Write-Host -Object ('Total workstations found in AD: {0}' -f $TotalWorkstations) -ForegroundColor Green
    Write-Host -Object ('Total workstations not responding: {0}' -f $BadCount) -ForegroundColor Red
    Write-Host -Object "This test was run by $env:USERNAME from $env:COMPUTERNAME"
    Write-Host -Object ('You can find the full report at: {0}' -f $OutputFileNameReport)
  }
}

function Test-FiberSatellite
{
  <#
      .SYNOPSIS
      "Pings" a group of sites or servers and gives a response in laymans terms.

      .DESCRIPTION 
      "Pings" a group of sites or servers and gives a response in laymans terms. 
      This started due to our need to find out if transport was over fiber or bird.  
      There are some default remote sites that it will test, but you can pass your own if you only want to check one or two sites. 

      .PARAMETER Sites
      A single or list of sites or servers that you want to test against.

      .PARAMETER Simple
      Provides a single output line for those who just need answers.

      .PARAMETER Log
      Sends the output to a log file.

      .PARAMETER ReportFolder
      The folder where the output log will be sent.

      .EXAMPLE
      Test-FiberSatellite -Sites Value
      The default values are: ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com')
    
      .EXAMPLE
      Test-FiberSatellite -Simple
      Creates a simple output using the default site list

      .EXAMPLE
      Test-FiberSatellite -Log -ReportFile Value
      Creates a log file with the year and month to create a monthly log.

      .EXAMPLE
      Test-FiberSatellite -Log -ReportCsv Value
      If the file exist is will add the results to that file for trending.  If it doesn't exist, it will create it.

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.Tools/wiki/Test-FiberSatellite

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      To console or screen at this time.
  #>
  <#PSScriptInfo

      .VERSION 4.0

      .GUID 676612d8-4397-451f-b6e3-bc3ae055a8ff

      .AUTHOR Erik

      .COMPANYNAME Knarr Studio

      .COPYRIGHT

      .TAGS Test, Console, NonAdmin User

      .LICENSEURI

      .PROJECTURI  https://github.com/KnarrStudio/ITPS.OMCS.Tools

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES NetTCPIP

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES

      .PRIVATEDATA

  #>

  [cmdletbinding(DefaultParameterSetName = 'Default')]
  param
  (
    [Parameter(Position = 0)]
    [String[]] $Sites = ('localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Parameter (ParameterSetName = 'Default')]
    [Switch]$Simple,
    [Parameter (ParameterSetName = 'Log')]
    [Switch]$Log,
    [Parameter (ParameterSetName = 'Log')]
    [String]$ReportFile = "$env:SystemDrive/temp/Reports/FiberSatellite/FiberSatellite.log",
    [Parameter(Mandatory,HelpMessage = 'CSV file that is used for trending',Position = 1,ParameterSetName = 'Log')]
    [ValidateScript({
          If($_ -match '.csv')
          {
            $true
          }
          Else
          {
            Throw 'Input file needs to be CSV'
          }
    })][String]$ReportCsv
  )
  
  #region Initial Setup
  function script:f_CurrentLineNumber 
  {
    <#
        .SYNOPSIS
        Get the line number at the command
    #>


    $MyInvocation.ScriptLineNumber
  } 
  
  #region Variables   
  $TimeStamp = Get-Date -Format G 
  $ReportList = [Collections.ArrayList]@()
  $null = @()
  $TotalResponses = $RttTotal = $NotRight = 0
  $TotalSites = $Sites.Count
  $YearMonth = Get-Date -Format yyyy-MMMM
    
  
  $OutputTable = @{
    Title  = "`nThe Ping-O-Matic Fiber Tester!"
    Green  = ' Round Trip Time is GOOD!'
    Yellow = ' The average is a little high.  An email will be generated to send to the Netowrk team to investigate.'
    Red    = ' Although not always the case this could indicate that you are on the Satellite.'
    Report = ''
  }
  
  $VerboseMsg = @{
    1 = 'Place Holder Message'
    2 = 'Log Switch set'
    3 = 'ReportCsv Test'
    4 = 'Column Test'
    5 = 'Region Setup Files'
    6 = 'Create New File'
  }
  
  $PingStat = [Ordered]@{
    'DateStamp' = $TimeStamp
  }
  
  #endregion Variables 
    
  #region Setup Log file
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $VerboseMsg.5)
  $ReportFile = [String]$($ReportFile.Replace('.',('_{0}.' -f $YearMonth)))
    
  If(-not (Test-Path -Path $ReportFile))
  {
    Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $VerboseMsg.6)
    $null = New-Item -Path $ReportFile -ItemType File -Force
  }
  
  # Log file - with monthly rename
  $OutputTable.Title | Add-Content -Path $ReportFile 
  ('-'*31) | Add-Content -Path $ReportFile 
  
  #endregion Setup Log file
  
  
  #region Setup Output CSV file
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $VerboseMsg.5)
  if($ReportCsv) 
  {
    if(Test-Path -Path $ReportCsv)
    {
      # Trending CSV file setup and site addition
      Write-Verbose -Message ('Line {0}:  {1}' -f $(f_CurrentLineNumber), $VerboseMsg.3)
      $PingReportInput = Import-Csv -Path $ReportCsv
      $ColumnNames = ($PingReportInput[0].psobject.Properties).name
      # Add any new sites to the report file
      foreach($site in $Sites)
      {
        Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $site)
        if(! $ColumnNames.contains($site))
        {
          Write-Verbose -Message ('Line {0}:  {1}' -f $(f_CurrentLineNumber), $VerboseMsg.4)
          $PingReportInput | Add-Member -MemberType NoteProperty -Name $site -Value $null -Force
          $PingReportInput  | Export-Csv -Path $ReportCsv -NoTypeInformation
        }
      }
    }
    else
    {
      $null = New-Item -Path $ReportCsv -ItemType File -Force
    }
  }
  #endregion Setup Output CSV file
  
  #endregion Initial Setup
  
  ForEach ($site in $Sites)  
  {
    Write-Verbose -Message ('Line {0}: site: {1}' -f $(f_CurrentLineNumber), $site)
    $PingReply = Test-NetConnection -ComputerName $site 
    
    $RoundTripTime = $PingReply.PingReplyDetails.RoundtripTime
    $RemoteAddress = $PingReply.RemoteAddress
    $PingSucceded = $PingReply.PingSucceeded
    $RemoteComputerName = $PingReply.Computername

    if($PingSucceded -eq $true)
    {
      $TotalResponses = $TotalResponses + 1
      $RttTotal += $RoundTripTime
      $OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $site, $RoundTripTime)
    
      Write-Verbose -Message ('Line {0}: RttTotal {1}' -f $(f_CurrentLineNumber), $RttTotal)
    }
    if($PingSucceded -eq $false)
    {
      #$TotalResponses = $TotalResponses - 1
      $NotRight ++
      $OutputMessage = ('{0} - Did not reply' -f $site)
    }
    
    #$OutputMessage = ('{0} - RoundTripTime is {1} ms.' -f $site, $RoundTripTime)
    
    $OutputMessage | Add-Content -Path $ReportFile
    
    Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $OutputMessage)
    $ReportList += $OutputMessage
    
    $PingStat[$site] = $RoundTripTime
  }
  
  $RoundTripTime = $RttTotal/$TotalResponses
  $TimeStamp = Get-Date -Format G 
  
  $OutputTable.Report = ('{1} - {3} tested {0} remote sites and {2} responded. The average response time: {4}ms' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME, [int]$RoundTripTime) 
  
  Write-Verbose -Message ('Line {0}: Message: {1}' -f $(f_CurrentLineNumber), $OutputTable.Report)

  #region Console Output
  If(-Not $Log)
  {
    Write-Output -InputObject $OutputTable.Report
  }
  if((-not $Simple) -and (-not $Log))
  {
    Write-Output -InputObject $OutputTable.Title 
    if($RoundTripTime -gt 380)
    {
      Write-Host -Object ('  ') -BackgroundColor Red -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Red)
    }
    ElseIf($RoundTripTime -gt 90)
    {
      Write-Host -Object ('  ') -BackgroundColor Yellow -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Yellow)
    }
    ElseIf($RoundTripTime -gt 1)
    {
      Write-Host -Object ('  ') -BackgroundColor Green -ForegroundColor White -NoNewline
      Write-Output -InputObject ($OutputTable.Green) 
    }
    if($NotRight -gt 0)
    {
      Write-Output -InputObject ('{0} Responded with 0 ms.  If you tested the "Localhost" one would be expected.' -f $NotRight)
    }
  }
  #endregion Console Output
 

  $LogOutput = (
    @'

{0}
{2}
{3}
'@ -f $(f_$OutputTable.Report), ('-' * 31), ('You can find the full report at: {0}' -f $ReportFile), ('=' * 31))

  $LogOutput | Add-Content -Path $ReportFile
    
  Start-Process -FilePath notepad -ArgumentList $ReportFile
    
    
  #region File Output 
  If($Log)
  {
    # Export the hashtable to the file
    $PingStat |
    ForEach-Object -Process {
      [pscustomobject]$_
    } |     
    Export-Csv -Path $ReportCsv -NoTypeInformation -Force -Append
  }
  #endregion File Output 
}

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
    function script:f_Timestamp 
    {
      <#
          .SYNOPSIS
          Time stamp in format - 2/17/2020 10:56:12 
      #>
      Write-Debug -Message 'function TimeStamp'
      $(f_Get-Date -Format G)
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
        [string] $TimeStamp = (f_Timestamp),
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
  
    $TimeStamp = f_Timestamp
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

          $FileTest = $(f_Get-Content -Path $ServerShareFile  | Select-String -Pattern $ReplicaStatement)
          Write-Debug -Message ('File test returns: {0}' -f $FileTest)
        
          If($FileTest)
          {
            break
          }
        }

        if($FileTest)
        {
          $TimeStamp = f_Timestamp
          Save-Results -TimeStamp $TimeStamp -Server $Server -Status Good -ReplicaStatement $ReplicaStatement -ServerShareFile $ServerShareFile 
        }
        else
        {
          $TimeStamp = f_Timestamp
          Save-Results -TimeStamp $TimeStamp -Server $Server -Status Failed -ReplicaStatement $ReplicaStatement -ServerShareFile $ServerShareFile 
        }
      }
      Else 
      {
        $TimeStamp = f_Timestamp
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

