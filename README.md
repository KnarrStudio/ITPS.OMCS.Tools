# ITPS.OMCS.Tools 
### IT PowerShell Open Minded Common Sense Tools 
#### (No connection to the MIT OMCS project) 


This is the second go around of some tools.  The first was a bunch of scripts, this one although different in not just the exact scripts, but also these have been written as a module.   

The original idea was to create a series of tools that could be used by the desk side support tech, but during testing I found that having to make sure the script was signed and had to "Run-As" an administrator.  Both of those were problems that I wanted to get around.  So, moving forward, although scripts will be signed, they will be designed so that you can run them as a normal user.   

### Tools: 
         
* _Get-SystemUpTime_             
* _Get-InstalledSoftware_        
* _Test-PrinterStatus_           
* _Add-NetworkPrinter_           
* _Test-SQLConnection_           
* _Write-Report_                 
* _Test-AdWorkstationConnections_
* _Test-FiberSatellite_          
* _Test-Replication_             
* _Compare-Folders_              
* _Set-FolderRedirection_        
* _Get-FolderRedirection_        



* **Add-NetworkPrinter** - This will help you add a printer to your workstation or server.  You need to know the Print Server Name. 
* **Compare-Folders** - This allows you the ability to compare the files in two folders. 
* **Get-InstalledSoftware** - This returns the version of the software named. 
* **New-TimedStampFileName** - One of my original funtions.  It just spits out a file name with a time stamp. 
* **Repair-FolderRedirection** - This will make the changes in the registry to fix folder redirection for the folders that were used at the place I worked when I wrote it. 
* **Test-AdWorkstationConnections** - Collects a list of computers from AD base the the Searchbase you provide and returns two files, first is the full list of computers the next is a list of computer that not responded to the "ping".  Because it uses the Net bios name to ping, this also tests the DNS servers.  It also gives a list of all of the computers that are in the searchbase. 
* **Test-FiberSatellite** - "Pings" servers based on your input.  It pings the big search engine websites. 
* **Test-PrinterStatus** - Similar to the AD workstation connection is does the same for printers. You have to provide the printserver name.  
* **Test-Replication** - Perform a test to ensure Replication is working.  You must know at least two of the replication partners

```PowerShell 

Test-FiberSatellite -Sites Value -Simple

``` 

### Module Downloads:  

Latest Version at [PowerShell Gallery](https://www.powershellgallery.com/packages/ITPS.OMCS.Tools/1.8.1)  

At [Github](https://github.com/KnarrStudio/ITPS.OMCS.Tools) 


