# Add "Title of Menu" with a script block and hotkeys 'Ctrl+Alt+B'
# Import the ITPS-SelfHelp module
# Initialize the Menu Object
$MenuObject = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Self Help', $null, $null)

# Define the Submenu Object
$MenuObject.Submenus.Add('Test the Internet', {Test-TheInternet}, 'Ctrl+Alt+T')
# $MenuObject.Submenus.Add('Convert IP Address to Binary', {Convert-IPAddresstoBinary}, $null)
$MenuObject.Submenus.Add('Test Authentication Server', {Test-AuthenticationServer}, 'Ctrl+Alt+A')

# Uncomment to use scripts from user profile path
# $MenuObject.Submenus.Add('Test the Internet', {
#     . $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-TheInternet.ps1
# }, 'Ctrl+Alt+T')
# $MenuObject.Submenus.Add('Compare File Hash', {
#     . $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Compare-FileHash.ps1
# }, 'Ctrl+Alt+F')
# $MenuObject.Submenus.Add('Test Authentication Server', {
#     . $env:USERPROFILE\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-AuthenticationServer.ps1
# }, 'Ctrl+Alt+A')
# $MenuObject.Submenus.Add('Ping IP Range', {
#     . $env:USERPROFILE\Documents\GitHub\AssetManagementApp\Ping-IpRange.ps1
# }, 'Ctrl+Alt+P')

########################################
# Clear the Add-ons menu if needed
# $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Clear()

# Example to create an AddOns menu with an accessor
# Note the use of "_" as opposed to "&" for mapping to the fast key letter for the menu item
# $menuAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('_Process', {Get-Process}, 'Alt+P')

# Example to add a nested menu
# $parentAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('Parent', $null, $null)
# $parentAdded.SubMenus.Add('_Dir', {dir}, 'Alt+D')

# Display the Add-ons menu on the current PowerShell tab
# $psISE.CurrentPowerShellTab.AddOnsMenu
