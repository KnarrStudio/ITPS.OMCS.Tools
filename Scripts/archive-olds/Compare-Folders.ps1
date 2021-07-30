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



# SIG # Begin signature block
# MIID/AYJKoZIhvcNAQcCoIID7TCCA+kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUw+5Q5rbHWy1OhWgTnWnoK07S
# nv6gggIRMIICDTCCAXagAwIBAgIQapk6cNSgeKlJl3aFtKq3jDANBgkqhkiG9w0B
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUEn6HOQ6J
# BNjhOuZ0Y0kO75i1J+swDQYJKoZIhvcNAQEBBQAEgYBc8iPcekHnCgexxvkId3if
# lNkJ3WseAyyYYLOmo5oi2Wu/eO17eOdeInaRRJ8ulK1lDC0sNuLebjJMtcElPHeN
# ub2f2pcEl+xwwfV7Rt1YKRaw9w+pjZCP6kqrAAJ+2F6N43a+P+Y+1fezM5Jcig+Y
# iL7POcfn7UuauwOuohP0qg==
# SIG # End signature block
