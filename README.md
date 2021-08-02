# ITPS.OMCS.Tools 
### IT PowerShell Open Minded Common Sense Tools 
#### (No connection to the MIT OMCS project) 


This is the ~~second~~ third go around of some tools.  The original idea was to create a series of tools that could be used by the desk side support tech. I found that some of the tasks that were being completed didn't need to have elevated rights, so I recreated this toolset to be run as the logged on users.  Now, months later and a better understanding of modules, Github and life overall, I have done some updates to the overall module and some changes to the code.I found that having to make sure the script was signed and had to "Run-As" an administrator.  Both of those were problems that I wanted to get around.  So, moving forward, although scripts will be signed, they will be designed so that you can run them as a normal user.   

### Original Toolset: 
* **Add-NetworkPrinter** - _Unchanged_ You need to know the Print Server Name.  It will provide a list of printers that you are allowed to print to.   
* **Compare-Folders** - _Minor Changes_ This version allows you to identify a parent folder before select the two to compare. 
* **Get-InstalledSoftware** - _Unchanged_ This returns the version of the software named. 
* **New-TimedStampFileName** - _Removed_ One of my original funtions that I used in early scripting.  It just spits out a file name with a time stamp. It really didn't grow, so it has been removed from this module, and rewritten as _New-TimeStampFile_ which actually creates the file.  And moved to the _ITPS.OMCS.CodingFunction_ module.  
* **Repair-FolderRedirection** - _Major Changes_ This has been changed from a single script which did both report and fix to two.  See below: Get-FolderRedirection and Set-FolderRedirection. 
* **Test-AdWorkstationConnections** - _Unchanged_ Collects a list of computers from AD base the the Searchbase you provide and returns two files, first is the full list of computers the next is a list of computer that not responded to the "ping".  Because it uses the Net bios name to ping, this also tests the DNS servers.  It also gives a list of all of the computers that are in the searchbase. 
* **Test-FiberSatellite** - _Unchanged_ "Pings" servers based on your input and gives an does the math and gives an average.  This was setup, where it was important to know if we were working over the fiber (~60ms average) or over the satellite (+600ms average). By default it pings the big search engine websites. 
**Output example:**
         8/2/2021 14:09:13 - _username_ tested 5 remote sites and 5 responded. The average response time: 33ms
         The Ping-O-Matic Fiber Tester!
         Round Trip Time is GOOD!

* **Test-PrinterStatus** - Similar to _Test-AdWorkstationConnections_, but for printers. You have to provide the printserver name.  
* **Test-Replication** - This is a manual "brut force" test of DFSR.  It writes to a file on one node and reads it on its replication partner, then does the same thing in reverse.  You must know at least two of the replication partners. 

### New Tools:
* **Get-SystemUpTime** - This was build after users lieing or not understanding what a Reboot is.  
        It will give you the following: _ComputerName, LastBoot, TotalHours_ 
* **Get-FolderRedirection** - _NEW_ Returns the location of the user's files.  This is a way to make sure there is nothing wrong with the folder redirection and they are saving to the HD.          
* **Set-FolderRedirection** - _NEW_ Changes the location of the user's files and copies them if needed.  This will make the changes in the HKCU registry to fix folder redirection. 


```PowerShell 

Import-Module -Scope Local # When using this as a normal user.

``` 

### Module Downloads:  

Version 1.8.1 has been uploaded to the [PowerShell Gallery](https://www.powershellgallery.com/packages/ITPS.OMCS.Tools/1.8.1)  

This current version 1.12.2.8 is only available at [Github](https://github.com/KnarrStudio/ITPS.OMCS.Tools) under the **Module Testing** branch.


