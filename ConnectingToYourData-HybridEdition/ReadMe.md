# Connecting to Your Data - Hybrid Edition

This Folder contains supplemental code for our session [Connecting to Your Data - Hybrid Edition](https://mms2024fll.sched.com/event/1eiHW/connecting-to-your-data-hybrid-edition) presented at [MMS Flamingo Edition](https://mmsmoa.com).

Our main sources of data are the ones below:

* Active Directory
* Configuration Manager
* Intune/Entra Id (Graph)
* MBAM (for bitlocker data, for those that still use it)

# Contents

|File|Description|
|---|---|
|Get-AD-Stuff.ps1|Various methods for extracting Computers and BitLocker Keys from AD, including Active Directory Cmdlets, DirectorySearcher .Net objects, and COM objects with ADSI.|
|Get-CM-Stuff.ps1|Various methods for extracting Computers and BitLocker Keys from ConfigMgr using WMI, SQL, Admin Service (REST), and CM Cmdlets.|
|Get-Graph-Stuff.ps1|Various methods for extracting Computers and BitLocker Keys from Intune/MEID through graph using REST calls and Microsoft.Graph PowerShell SDK.|
|Get-Mbam-Stuff.ps1|If you're still using it, some queries to get the computer information from MBAM.  Also, PowerShell to interface the SOAP api and get the bitlocker keys from it.|
|Find-wsBitLockerKey.ps1|A example powershell tool built as a wpf UI that will check AD, CM, MBAM, & MEID for your BitLocker keyid and return the recovery key.|
|Import-DataToSQL.ps1|An Advanced collection of queries pulling data from various sources and importing them into a SQL database to allow easy retrieval and refresh of your data.|
