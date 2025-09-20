
# .Add("Title of Menu",{Scriptblock},"HotKeys 'Ctrl+Alt+B'")

# Import-Module ITPS-SelfHelp

# Create the Menu Object
$MenuObject = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Self Help',$null,$null) 


# Create the Submenu Object
$MenuObject.Submenus.Add('Test the Internet',{Test-TheInternet},'Ctrl+Alt+T')  
#$MenuObject.Submenus.Add('Convert IP Address to Binary',{Convert-IPAddresstoBinary},$null)
$MenuObject.Submenus.Add('Test Authentication Server',{Test-AuthentationServer},'Ctrl+Alt+A')




<#
$MenuObject.Submenus.Add('Test the Internet',{
    $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-TheInternet.ps1
},'Ctrl+Alt+T')   
$MenuObject.Submenus.Add('Compare File Hash',{
    . $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Compare-FileHash.ps1
},'Ctrl+Alt+F')
$MenuObject.Submenus.Add('Test Authentication Server',{
    $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-AuthentationServer.ps1
},'Ctrl+Alt+A')
$MenuObject.Submenus.Add('Ping IP Range',{
    . $env:USERPROFILE\Documents\GitHub\AssetManagentapp\Ping-IpRange.ps1
},'Ctrl+Alt+P')
#>



########################################
# Clear the Add-ons menu
#$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Clear()

# Create an AddOns menu with an accessor.
# Note the use of "_"  as opposed to the "&" for mapping to the fast key letter for the menu item.
#$menuAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('_Process', {Get-Process}, 'Alt+P')

# Add a nested menu.
#$parentAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('Parent', $null, $null)
#$parentAdded.SubMenus.Add('_Dir', {dir}, 'Alt+D')

# Show the Add-ons menu on the current PowerShell tab.
#$psISE.CurrentPowerShellTab.AddOnsMenu





