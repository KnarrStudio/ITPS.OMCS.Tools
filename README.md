# ITPS.OMCS.Tools 
### IT PowerShell Open Minded Common Sense Tools 
#### (No connection to the MIT OMCS project) 


This is the second go around of some tools.  The first was a bunch of scripts, this one although different in not just the exact scripts, but also these have been written as a module.   

The original idea was to create a series of tools that could be used by the desk side support tech, but during testing I found that having to make sure the script was signed and had to "Run-As" an administrator.  Both of those were problems that I wanted to get around.  So, moving forward, although scripts will be signed, they will be designed so that you can run them as a normal user.   

### Tools: 
* **Add-NetworkPrinter** - (Archived) This would help add a printer; archived implementation at `Scripts\_Archived\Add-NetworkPrinter.ps1` and `Modules\_Archived\Add-NetworkPrinter.psm1`.
* **Compare-Folders** - This allows you the ability to compare the files in two folders. 
* **Get-InstalledSoftware** - (Archived) This returns the version of the software named. See `Scripts\_Archived\Get-InstalledSoftware.ps1` for the archived implementation.
* **New-TimedStampFileName** - One of my original funtions.  It just spits out a file name with a time stamp. 
* **Repair-FolderRedirection** - This will make the changes in the registry to fix folder redirection for the folders that were used at the place I worked when I wrote it. 
* **Test-AdWorkstationConnections** - Collects a list of computers from AD base the the Searchbase you provide and returns two files, first is the full list of computers the next is a list of computer that not responded to the "ping".  Because it uses the Net bios name to ping, this also tests the DNS servers.  It also gives a list of all of the computers that are in the searchbase. 
* **Test-FiberSatellite** - (Archived) "Pings" servers based on your input. The original implementation is archived at `Modules\_Archived\Test-FiberSatellite.psm1` for historical reference.
* **Test-PrinterStatus** - Similar to the AD workstation connection is does the same for printers. You have to provide the printserver name.  
* **Test-Replication** - Perform a test to ensure Replication is working.  You must know at least two of the replication partners

```PowerShell 

Test-FiberSatellite -Sites Value -Simple

``` 

### Module Downloads:  

Latest Version at [PowerShell Gallery](https://www.powershellgallery.com/packages/ITPS.OMCS.Tools/1.8.1)  

At [Github](https://github.com/KnarrStudio/ITPS.OMCS.Tools) 


