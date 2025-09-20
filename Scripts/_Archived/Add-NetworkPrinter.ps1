function Add-NetworkPrinter
{
  <#
      Archived copy of Add-NetworkPrinter
      Use for reference or restoration.
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

  Write-Warning 'This is an archived copy of Add-NetworkPrinter. Use for reference only.'
}
