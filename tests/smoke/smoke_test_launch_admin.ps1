# Smoke test for Start-AdminPowerShell
# This test imports the module and verifies the exported command exists.

$modulePath = "$PSScriptRoot\..\..\Modules\LaunchAdminPowerShellConsole.psm1"
Write-Host "Importing module from: $modulePath"
Import-Module $modulePath -Force -ErrorAction Stop

$cmd = Get-Command -Name Start-AdminPowerShell -ErrorAction SilentlyContinue
if ($null -eq $cmd) {
    Write-Error "Start-AdminPowerShell not found after import"
    exit 1
}
else {
    Write-Host "Start-AdminPowerShell is available: $($cmd.Name)"
    exit 0
}
