function Test-FiberSatellite
{
  <#
      .SYNOPSIS
      "Pings" a group of sites or servers and gives a response in laymans terms.

      .DESCRIPTION
      This started due to our need to find out if we were running on Fiber or not.  There are some default off island sites that it will test, but you can pass them if you only want to check one or two sites.

      .PARAMETER Sites
      A single or list of sites or servers that you want to test against.

      .PARAMETER OneLineOutput
      Provides a single output line for those who just need answers.

      .EXAMPLE
      Test-FiberSatellite -Sites Value -OneLineOutput
      Tests the Value and displays the output as a single line of text

      .NOTES
      Place additional notes here.

      .LINK
      https://github.com/KnarrStudio/ITPS-Tools/wiki

      .OUTPUTS
      To console or screen at this time.
  #>

  param
  (
    [Parameter(Position = 0)]
    [Object[]] $Sites = ('LocalServer', 'localhost', 'www.google.com', 'www.bing.com', 'www.wolframalpha.com', 'www.yahoo.com'),
    [Switch]$OneLineOutput
  )
  
  $RttTotal = $NotRight = 0
  $TotalResponses = $TotalSites = $Sites.Count
  function Test-Verbose 
  {
    [Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference
  }
    if(-not $OneLineOutput)
    {
    Write-Host ('The Ping-O-Matic Fiber Tester!') -BackgroundColor DarkYellow -ForegroundColor White}
  ForEach ($Site in $Sites)  
  {
    $PingReply = Test-NetConnection -ComputerName $Site 
    if($PingReply.PingSucceeded -eq $true)
    {
      $RTT = $PingReply.PingReplyDetails.RoundtripTime
      $RttTotal = $RttTotal + $RTT
    
      if($RTT -eq 0)
      {
        $TotalResponses = $TotalResponses - 1
        $NotRight = $NotRight + 1
      }
      Write-Verbose -Message ('{0} - RoundTripTime is {1} ms.' -f $PingReply.Computername, $RTT)
    }
    Else
    {
      $TotalResponses = $TotalResponses - 1
    }
  }

  $RTT = $RttTotal/$TotalResponses
  $TimeStamp = Get-Date -Format 'dd-MMM-yyyy HH:mm'
  if(-not $OneLineOutput)
  {
    <#    if(Test-Verbose)
    {#>
    if($RTT -gt 380)
    {
      Write-Host('Although not always the case this could indicate that you are on the Satellite backup circuit.') -BackgroundColor Red -ForegroundColor White
    }
    ElseIf($RTT -gt 90)
    {
      Write-Host ('Although not always the case this could indicate that you are on the Puerto Rico backup circuit.') -BackgroundColor Yellow -ForegroundColor White
    }
    ElseIf($RTT -gt 1)
    {
      Write-Host ('Round Trip Time is GOOD!') -BackgroundColor Green -ForegroundColor White
    }
    # }
  }
  Write-Host ('{1} - {3} tested {0} off island computers and {2} responded. The average response time:' -f $TotalSites, $TimeStamp, $TotalResponses, $env:USERNAME) -ForegroundColor DarkYellow -NoNewline
  Write-Output -InputObject (' {0} ms' -f [int]$RTT)

  if($NotRight -gt 0)
  {
    Write-Output -InputObject ('{0} Responded with 0 ms' -f $NotRight)
  }

  <#  Write-Output -InputObject ('Average RTT is {0} ms.' -f [int]$RTT)
      if ($RTT -lt 380){
  Start-Process "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe" }#>
}