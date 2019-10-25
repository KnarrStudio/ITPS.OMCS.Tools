function Compare-Folders 
{
  <#
      .SYNOPSIS
      Compare two folders for clean up

      .EXAMPLE
      Compare-Folders -FolderSource "C:\Temp" -FolderDest"\\Network\Fileshare" -Verbose
      
      .PARAMETER FirstFolder
      The source folder -FirstFolder.

      .PARAMETER SecondFolder
      The Destination -SecondFolder.

  #>
    

  [Cmdletbinding()]
  
  Param
  (
    [Parameter(Mandatory, Position = 0,ValueFromPipeline, ValueFromPipelineByPropertyName)] [Alias('Source','OldFolder')]
    [string]$FirstFolder,
    [Parameter(Mandatory=$False)][Alias('Destination','Staging')]
  [string]$SecondFolder = $null  )

  function Get-FolderStats
  {
    [CmdletBinding()]
    Param
    (
      [Parameter(Mandatory = $true, Position = 0)]
      [Object]$InputItem
    )
    $folderSize = (Get-ChildItem -Path $InputItem -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue)
    '{0:N2} MB' -f ($folderSize.Sum / 1MB)
    Write-Debug -Message ('{0} = {1}' -f $InputItem, $('{0:N2} MB' -f ($folderSize.Sum / 1MB)))
    Write-Verbose -Message ('Folder Size = {0}' -f $('{0:N2} MB' -f ($folderSize.Sum / 1MB)))
  }
  
  function Get-Recursed 
  {
    Param
    (
      [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
      [String]$InputItem
    )
    Process
    {
      $SelectedFolderItems = Get-ChildItem -Path $InputItem -Recurse -Force

      Write-Debug -Message ('Get-Recursed = {0}' -f $InputItem)
      Write-Verbose -Message ('Get-Recursed = {0}' -f $InputItem)
      if($SelectedFolderItems -eq $null){
        $SelectedFolderItems = Get-ChildItem -Path $InputItem -Recurse -Force
      }
      Return $SelectedFolderItems = Get-ChildItem -Path $InputItem -Recurse -Force
  }}
  
  function Select-FolderToCompare
  {
    [CmdletBinding()]
    Param
    (
      [Parameter(Mandatory = $true, Position = 0)][String]$InputItem,
      [Parameter(Mandatory = $true, Position = 1)][String]$Title
    )
    $FolderSelected = (Get-ChildItem -Path $InputItem |
      Select-Object -Property Name, FullName |
    Out-GridView -Title $Title -OutputMode Single ).fullname

    Write-Verbose -Message ('FolderSourceSelected  = {0}' -f $FolderSelected)
    Write-Debug -Message ('FolderSourceSelected  = {0}' -f $FolderSelected)
    
    Return $FolderSelected
  }

  if(-not $SecondFolder){
    $SecondFolder = [String]$FirstFolder
  }

  $FirstFolderSelected = Select-FolderToCompare  -InputItem $FirstFolder -Title 'Select Folder to Compare' 
  if($FirstFolderSelected -eq $null)
  {
    $FirstFolderSelected = 'Nothing Selected'
    Break
  }
  Write-Debug -Message ('FirstFolderSelected  = {0}' -f $FirstFolderSelected)
  
  $SecondFolderSelected = Select-FolderToCompare -InputItem $SecondFolder -Title "Compare to $FirstFolderSelected"
  if($SecondFolderSelected -eq $null)
  {
    $SecondFolderSelected = 'Nothing Selected'
    Break
  }
  Write-Debug -Message ('SecondFolderSelected  = {0}' -f $SecondFolderSelected)


  #$FirstCompare = Get-ChildItem -Path $FirstFolderSelected -Recurse -Force # 
  $FirstCompare = Get-Recursed -InputItem $FirstFolderSelected
  Write-Debug -Message ('FirstCompare  = {0}' -f $FirstCompare)

  #$SecondCompare = Get-ChildItem -Path $SecondFolderSelected -Recurse -Force #
  $SecondCompare = Get-Recursed -InputItem $SecondFolderSelected
  Write-Debug -Message ('SecondCompare  = {0}' -f $SecondCompare)

  Compare-Object -ReferenceObject $FirstCompare -DifferenceObject $SecondCompare
  

  Write-Verbose -Message ('FolderSourceSize = {0}' -f $(Get-FolderStats -InputItem $FirstFolderSelected))
  Write-Verbose -Message ('FolderDestSize = {0}' -f $(Get-FolderStats -InputItem $SecondFolderSelected))
  Write-Verbose -Message ("'<=' only in {0} " -f $FirstFolderSelected) 
  Write-Verbose -Message ("'=>' only in {0} " -f  $SecondFolderSelected) 
}