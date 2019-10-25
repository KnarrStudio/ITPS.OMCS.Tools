function Test-AdWorkstationConnections
{

  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
  param(

    [Parameter(Mandatory=$false, Position=1)]
    [String]
    $ADSearchBase = 'OU=Clients-Desktop,OU=Computers,DC=Knarrstudio,DC=net',
    
    [Parameter(Mandatory=$false, Position=0)]
    [String]
    $PingReportFolder = '\\server\share\Reports\PingReport',

        [Parameter(Mandatory=$false, Position=2)]
    [string]
    $OutputFileName = 'AdDesktop',
    
       [Switch]$Bombastic
  )
  
  $i = 1
  $BadCount = 0
  $DateNow = Get-Date -UFormat %Y%m%d-%H%M
  $OutputFileName = ('{0}\{1}-{2}_Results.csv' -f $PingReportFolder, $DateNow,$OutputFileName)
  $WorkstationSiteList = ('{0}\{1}-{2}_List.csv' -f $PingReportFolder, $DateNow,$OutputFileName)
  

  if(!(Test-Path -Path $PingReportFolder))
  {
    New-Item -Path $PingReportFolder -ItemType Directory
  }
  
  Get-ADComputer -filter * -SearchBase $ADSearchBase -Properties * |
  Select-Object -Property Name, LastLogonDate, Description |
  Sort-Object -Property LastLogonDate -Descending |
  Export-Csv -Path $WorkstationSiteList -NoTypeInformation
  
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
            $WorkstationProperties | Export-Csv -Path $OutputFileName -NoClobber -NoTypeInformation
          }
          else
          {
            $WorkstationProperties | Export-Csv -Path $OutputFileName -NoTypeInformation -Append
          }
        }
      }
    }
  }
  
  if ($Bombastic)
  {
    Write-Host ('Total workstations found in AD: {0}' -f $TotalWorkstations) -ForegroundColor Green
    Write-Host ('Total workstations not responding: {0}' -f $BadCount) -ForegroundColor Red
    Write-Host "This test was run by $env:USERNAME from $env:COMPUTERNAME"
    Write-Host ('You can find the full report at: {0}' -f $OutputFileName)
  }
}