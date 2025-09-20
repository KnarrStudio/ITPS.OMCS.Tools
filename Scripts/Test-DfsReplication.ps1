#!/usr/bin/env powershell
#requires -Version 5.1
#requires -Modules DFS

function Test-DfsReplication {
    <#
    .SYNOPSIS
    Tests DFS Replication functionality between multiple servers using a probe file.

    .DESCRIPTION
    Validates DFS Replication by:
    1. Creating a timestamped test file on the primary server
    2. Monitoring replication to partner servers
    3. Verifying content synchronization
    4. Providing detailed status reporting

    The function tests both file creation and content replication across
    all specified DFS replication partners, with configurable timeout
    and detailed status reporting.

    .PARAMETER FilePath
    The path to the test file, starting with a backslash.
    Example: \ShareName\TestFolder\test.txt
    Must be a valid DFS path accessible on all replication partners.

    .PARAMETER DfsrServers
    Array of 2-5 server names that are DFS replication partners.
    The first server is considered the primary where the test file
    will be created.

    .PARAMETER ServerName
    Single server name to use for auto-discovering replication partners.
    This parameter is mutually exclusive with DfsrServers.

    .PARAMETER TimeoutSeconds
    Maximum time in seconds to wait for replication to complete.
    Default: 30 seconds
    
    .PARAMETER Force
    Switch to overwrite existing test file if present.
    Default: False (will append to existing file)

    .PARAMETER Credential
    Optional credentials to use for DFSR operations and file access.

    .EXAMPLE
    Test-DfsReplication -DfsrServers "Server1","Server2" -FilePath "\Share\test.txt"
    Tests replication between two servers using the specified file path.

    .EXAMPLE
    Test-DfsReplication -DfsrServers "Server1","Server2","Server3" -FilePath "\Share\test.txt" -TimeoutSeconds 60
    Tests replication between three servers with a 60 second timeout.

    .EXAMPLE
    Test-DfsReplication -ServerName "Server1" -FilePath "\Share\test.txt"
    Auto-discovers all replication partners for Server1 and tests replication.

    .OUTPUTS
    Custom object containing:
    - Overall replication status
    - Per-server replication results
    - Timing information
    - Error details if any

    .NOTES
    Author: ITPS Team
    Requires: PowerShell 5.1 or later
    Dependencies: DFS PowerShell module
    Permissions: Requires read/write access to shares on all servers
    #>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = 'DFS path to test file (e.g., \Share\test.txt)'
        )]
        [ValidatePattern(
            '^\\[a-zA-Z0-9\-_]+\\[^\\/:*?"<>|]+$',
            ErrorMessage = 'FilePath must start with \ and be a valid file path'
        )]
        [string]$FilePath,

        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Manual',
            HelpMessage = 'Array of DFS replication partner servers (2-5)'
        )]
        [ValidateCount(2,5)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DfsrServers,

        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Auto',
            HelpMessage = 'Single server to auto-discover replication partners'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ServerName,

        [Parameter(HelpMessage = 'Maximum seconds to wait for replication')]
        [ValidateRange(5,300)]
        [int]$TimeoutSeconds = 30,

        [Parameter(HelpMessage = 'Overwrite existing test file if present')]
        [switch]$Force,

        [Parameter(HelpMessage = 'Credentials for DFSR operations')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
  
    begin {
        # Auto-discover replication partners if using ServerName parameter
        if ($PSCmdlet.ParameterSetName -eq 'Auto') {
            try {
                $params = @{
                    ComputerName = $ServerName
                    ErrorAction = 'Stop'
                }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $params['Credential'] = $Credential
                }

                Write-Verbose "Discovering replication partners for $ServerName..."
                
                # Get DFS replication group info
                $replicationGroups = Get-DfsReplicationGroup @params
                if (-not $replicationGroups) {
                    throw "No DFS replication groups found on $ServerName"
                }

                # Get all members from all replication groups
                $DfsrServers = @($ServerName) # Include source server as first element
                $DfsrServers += $replicationGroups | ForEach-Object {
                    Get-DfsReplicationGroupMember -GroupName $_.GroupName @params
                } | Select-Object -ExpandProperty ComputerName -Unique | 
                Where-Object { $_ -ne $ServerName }

                Write-Verbose "Discovered replication partners: $($DfsrServers -join ', ')"

                if ($DfsrServers.Count -lt 2) {
                    throw "No replication partners found for $ServerName"
                }
            }
            catch {
                throw "Failed to discover replication partners: $_"
            }
        }

        # Initialize result tracking
        $script:replicationResults = [ordered]@{
            StartTime = Get-Date
            PrimaryServer = if ($PSCmdlet.ParameterSetName -eq 'Auto') { $ServerName } else { $DfsrServers[0] }
            Status = 'NotStarted'
            Servers = [ordered]@{}
            ErrorCount = 0
        }

        # Status messages
        $script:statusMessages = @{
            Success = 'Replication completed successfully'
            Partial = 'Replication completed with some failures'
            Failed  = 'Replication failed to complete'
            Timeout = 'Replication timeout exceeded'
            Missing = 'Test file could not be created/accessed'
        }

        # Helper function to validate server connectivity
        function Test-ServerConnectivity {
            param ([string]$ServerName)
            
            Write-Verbose "Testing connectivity to $ServerName..."
            $result = Test-Connection -ComputerName $ServerName -Count 1 -Quiet
            
            if (-not $result) {
                Write-Warning "Cannot connect to server: $ServerName"
            }
            return $result
        }

        # Helper function to build full file path
        function Get-ReplicationPath {
            param ([string]$ServerName)
            
            return "\\$ServerName$FilePath"
        }

        # Helper function to create test content
        function New-TestContent {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            return "$timestamp - Replication test from $env:COMPUTERNAME by $env:USERNAME"
        }

        # Validate all servers are accessible
        $unreachableServers = $DfsrServers.Where{
            -not (Test-ServerConnectivity $_)
        }

        if ($unreachableServers) {
            throw "Cannot proceed - Unable to reach servers: $($unreachableServers -join ', ')"
        }
    }

    process {
        try {
            $primaryPath = Get-ReplicationPath -ServerName $replicationResults.PrimaryServer
            Write-Verbose "Primary test file path: $primaryPath"

            # Create or update test file on primary server
            try {
                if ($Force -and (Test-Path $primaryPath)) {
                    Remove-Item -Path $primaryPath -Force
                }
                
                $testContent = New-TestContent
                $testContent | Out-File -FilePath $primaryPath -Append
                Write-Verbose "Created test content on primary server"
                
                $replicationResults.TestContent = $testContent
                $replicationResults.Status = 'InProgress'
            }
            catch {
                throw "Failed to create/update test file on primary server: $_"
            }

            # Monitor replication to partner servers
            $startTime = Get-Date
            $timeout = $startTime.AddSeconds($TimeoutSeconds)
            
            do {
                $pendingServers = $DfsrServers | Where-Object { 
                    $_ -ne $replicationResults.PrimaryServer -and
                    $replicationResults.Servers[$_].Status -ne 'Success' 
                }

                foreach ($server in $pendingServers) {
                    $serverPath = Get-ReplicationPath -ServerName $server
                    Write-Verbose "Checking replication to $server..."

                    try {
                        if (Test-Path $serverPath) {
                            $content = Get-Content -Path $serverPath -Raw
                            if ($content -match [regex]::Escape($testContent)) {
                                $replicationResults.Servers[$server] = @{
                                    Status = 'Success'
                                    Time = (Get-Date)
                                    Path = $serverPath
                                }
                                Write-Verbose "Replication successful to $server"
                            }
                        }
                    }
                    catch {
                        Write-Warning ("Error checking replication on {0}: {1}" -f $server, $_)
                    }
                }

                if (-not $pendingServers) { break }
                
                Write-Progress -Activity "Monitoring Replication" -Status "$($pendingServers.Count) servers pending" -PercentComplete (
                    100 - (($timeout - (Get-Date)).TotalSeconds / $TimeoutSeconds * 100)
                )

                Start-Sleep -Seconds 1
            } while (Get-Date -lt $timeout)
        }
        catch {
            $replicationResults.Status = 'Failed'
            $replicationResults.ErrorCount++
            Write-Error $_
        }
    }

    end {
        # Calculate final status
        $replicationResults.EndTime = Get-Date
        $replicationResults.Duration = $replicationResults.EndTime - $replicationResults.StartTime
        
        $successCount = ($replicationResults.Servers.Values.Status -eq 'Success').Count
        $totalPartners = $DfsrServers.Count - 1  # Exclude primary server

        $replicationResults.Status = switch ($successCount) {
            $totalPartners { 'Success' }
            0 { 'Failed' }
            default { 'Partial' }
        }

        # Generate detailed report
        $report = [System.Text.StringBuilder]::new()
        $null = $report.AppendLine("DFS Replication Test Results")
        $null = $report.AppendLine("========================")
        $null = $report.AppendLine("Start Time: $($replicationResults.StartTime)")
        $null = $report.AppendLine("Duration: $($replicationResults.Duration.TotalSeconds) seconds")
        $null = $report.AppendLine("Status: $($replicationResults.Status)")
        $null = $report.AppendLine("Primary Server: $($replicationResults.PrimaryServer)")
        $null = $report.AppendLine("")
        $null = $report.AppendLine("Server Results:")
        $null = $report.AppendLine("-------------")

        foreach ($server in $DfsrServers | Where-Object { $_ -ne $replicationResults.PrimaryServer }) {
            $result = $replicationResults.Servers[$server]
            $null = $report.AppendLine("{0}:" -f $server)
            $null = $report.AppendLine("  Status: $($result.Status)")
            if ($result.Time) {
                $null = $report.AppendLine("  Completion Time: $($result.Time)")
            }
            $null = $report.AppendLine("  Path: $($result.Path)")
            $null = $report.AppendLine("")
        }

        # Output results
        Write-Output $report.ToString()

        # Return result object for pipeline
        [PSCustomObject]$replicationResults
    }
}