 function Write-ToConsole
  {
    <#
        .SYNOPSIS
        Short Description
    #>
    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Output from the "Ping Function"')]
      [Object]
      $InputObject
    )
  
    # Set Variables
    $AverageRTT = $TotalRtt = $TotalResponses = 0
    $InputObjectcount = $InputObject.count
    $TimeStamp = Get-Date -Format G
    $DateStamp = Get-Date -Format yyyy-MMM
  
    $OutputTable = @{
      Title     = "`nThe Ping-O-Matic Fiber Tester!"
      TimeStamp = $TimeStamp
      Green     = ' Round Trip Time is GOOD!'
      Yellow    = ' The average is a little high.  An email will be generated to send to the Netowrk team to investigate.'
      Red       = ' Although not always the case this could indicate that you are on the Satellite.'
      Report    = ''
    }

    # Write
    Foreach($site in $InputObject)
    {
      Write-Verbose -Message ('Site = {0}' -f $site)
      #region Math
      $TotalRtt += ($site.responseTime)
      if($site.PingResult -eq 'Success')
      {
        $TotalResponses ++
      }
      #endregion Math       
      ('{0,-3} ..... {1}' -f $site.ResponseTime, $site.Site) | Write-Output
    }
  
    # Calculate Average RTT
    $AverageRTT = $TotalRtt/$InputObjectcount
    Write-Verbose -Message ('Average Rtt = {0}' -f $AverageRTT)
 
    # Create the bottomlines
    $OutputTable.Report = (@'

{0,-3} ..... Average Response Time. 
{1} tested {2} remote sites and {3} responded. 


'@ -f $AverageRTT, $env:USERNAME, $InputObjectcount, $TotalResponses)

  }
  