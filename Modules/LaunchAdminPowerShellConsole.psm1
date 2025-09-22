<#
.SYNOPSIS
Launch an elevated PowerShell session and minimize the original console.

.DESCRIPTION
Provides `Start-AdminPowerShell` to start an elevated PowerShell process running the current script
when possible, or an elevated console otherwise, and minimize the original console window.

.EXAMPLE
Import-Module Modules\LaunchAdminPowerShellConsole.psm1
Start-AdminPowerShell
# Attempts to relaunch the current script elevated (if run from a file) or opens an elevated console.

.NOTES
This command will trigger UAC when starting the elevated process. The smoke test included with the
repository only imports the module and verifies the command is available; it does not call the function
to avoid prompting for elevation during automated test runs.
#>

function Start-AdminPowerShell {
    [CmdletBinding()]
    param ()

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@

    $SW_MINIMIZE = 6
    $SW_RESTORE  = 9

    $consoleHandle = [Win32]::GetConsoleWindow()

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {
        $scriptPath = $MyInvocation.MyCommand.Definition
        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            Write-Host "Opening an elevated PowerShell console..." -ForegroundColor Yellow
            Start-Process powershell -ArgumentList "-NoProfile -NoExit -ExecutionPolicy Bypass" -Verb RunAs
        }
        else {
            Write-Host "Relaunching as Administrator: $scriptPath" -ForegroundColor Yellow
            Start-Process powershell -ArgumentList "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        }

        try {
            if ($consoleHandle -ne [IntPtr]::Zero) {
                [Win32]::ShowWindow($consoleHandle, $SW_MINIMIZE) | Out-Null
            }
        }
        catch {
        }

        return
    }

    try {
        if ($consoleHandle -ne [IntPtr]::Zero) {
            [Win32]::ShowWindow($consoleHandle, $SW_RESTORE) | Out-Null
        }
    }
    catch {
    }

    Write-Host "You are now running PowerShell as Administrator!" -ForegroundColor Green
}

Export-ModuleMember -Function Start-AdminPowerShell
