#region Ad Searcher
#Build The object
$searcher = New-Object System.DirectoryServices.DirectorySearcher
#create your ldap query
$searcher.Filter = "(&(objectCategory=computer)(!(objectClass=msDS-GroupManagedServiceAccount))(!(objectClass=msDS-ManagedServiceAccount)))"
#Add properties that you want to load
$searcher.PropertiesToLoad.Add("name")
$searcher.PropertiesToLoad.Add("dNSHostName")
$searcher.PropertiesToLoad.Add("operatingSystem")
$searcher.PropertiesToLoad.Add("operatingSystemVersion")
$searcher.PropertiesToLoad.Add("lastLogon")
$searcher.PropertiesToLoad.Add("pwdLastSet")
$searcher.PropertiesToLoad.Add("lastLogonTimestamp")
$searcher.PropertiesToLoad.Add("lastLogon")
$searcher.PropertiesToLoad.Add("objectGUID")
$searcher.PropertiesToLoad.Add("objectSid")
$searcher.PropertiesToLoad.Add("pwdLastSet")
$searcher.PropertiesToLoad.Add("userAccountControl")
$searcher.PropertiesToLoad.Add("distinguishedName")
$searcher.PropertiesToLoad.Add("whenCreated")
$searcher.PageSize = 1000;
$results = $searcher.FindAll()

#some of the properties don't load in a very human readable format.  So, lets format them.
[System.Collections.Generic.List[object]]$computers = @() #lists are more efficient than a array.
foreach ($result in $results) {
    $computer = $result.Properties
    if ($computer.operatingsystem.count -gt 0){
        $OS=$computer.operatingsystem[0]
    }else{
        $OS=$null
    }
    if ($computer.operatingsystem.count -gt 0){
        $OSV=$computer.operatingsystemversion[0]
    }else{
        $OSV=$null
    }
    #an account being enables is a bitwise operator on the useraccountcontrol attribute. the 2 bit flags the account as disabled.
    $enabled = ($computer.useraccountcontrol[0] -band 2) -ne 2
    $created = $computer.whencreated[0]
    #some properties are stored as file times, which are intergers.  Format them to a date.
    $lastlogon = [DateTime]::FromFileTime($computer.lastlogon[0])
    $lastSet = [DateTime]::FromFileTime($computer.pwdlastset[0])
    $sid = (New-Object System.Security.Principal.SecurityIdentifier($computer.objectsid[0],0)).Value
    $computers.Add([PSCustomObject]@{
            dNSHostName        = $computer.dnshostname[0]
            Name               = $computer.name[0]
            OperatingSystem    = $OS
            OSVersion          = $OSV
            LastLogon          = $lastlogon
            ObjectGUID         = (Convert-ADGuid -bytes $computer.objectguid[0])
            ObjectSid          = $sid
            CreatedDate        = $created
            DistinguishedName  = $computer.distinguishedname[0]
            userAccountControl = $computer.useraccountcontrol[0]
            pwdLastSet         = $lastSet
            accountDisabled    = $enabled
        }
    )
}
$computers | Format-Table
#endregion Ad Searcher

#region Get-Adcomputer
$ADProperties = @(
    "name"
    "dNSHostName"
    "operatingSystem"
    "operatingSystemVersion"
    "lastLogon"
    "pwdLastSet"
    "lastLogonTimestamp"
    "lastLogon"
    "objectGUID"
    "objectSid"
    "pwdLastSet"
    "userAccountControl"
    "distinguishedName"
    "whenCreated"
)

$AdComputers = Get-ADComputer -Filter * -Properties $ADProperties


[System.Collections.Generic.List[object]]$computers = @()
foreach ($comp in $AdComputers){
    $computers.Add([PSCustomObject]@{
            dNSHostName            = $comp.DNSHostName
            Name                   = $comp.Name
            OperatingSystemVersion = $comp.OperatingSystemVersion
            operatingSystem        = $comp.OperatingSystem
            LastLogon              = [DateTime]::FromFileTime($comp.lastLogon)
            lastLogonTimestamp     = [DateTime]::FromFileTime($comp.lastLogonTimestamp)
            ObjectGUID             = $comp.ObjectGUID.Guid
            ObjectSid              = $comp.SID.Value
            CreatedDate            = $comp.whenCreated
            DistinguishedName      = $comp.distinguishedName
            userAccountControl     = $comp.userAccountControl
            pwdLastSet             = [DateTime]::FromFileTime($comp.pwdLastSet)
            Enabled                = $comp.Enabled
        })
}
#endregion Get-Adcomputer


#region BitLocker Ad Searcher
##Query for bitlocker keys using the ad searcher:
#guids are stored as hex arrays in ad.  This little function turns it into a readable string.
function Convert-ADGuid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $bytes
    )
    ([guid]::new($bytes)).Guid
}

#if you want to look up a object in AD via a specific guid, you have to convert it to the hex array to look it up.
function Convert-GuidToHexArray {
    param (
        [string]$guid
    )

    # Convert the string GUID to a .NET Guid object
    $guidBytes = [Guid]::Parse($guid).ToByteArray()

    # Convert each byte to a hexadecimal string and concatenate it in the required format
    $hexString = ""
    foreach ($byte in $guidBytes) {
        # Convert byte to 2-digit hexadecimal and append
        $hexString += "\" + "{0:X2}" -f $byte
    }

    return $hexString
}

# Define a searcher to query Active Directory
$searcher = New-Object DirectoryServices.DirectorySearcher

# Set the filter to search for all BitLocker Recovery Information
$searcher.Filter = "(&(objectClass=msFVE-RecoveryInformation))"
# Set the filter to search for a specific BitLocker Recovery key
#$searcher.Filter = "(&(objectClass=msFVE-RecoveryInformation)(msFVE-RecoveryGuid=$specificGuid))"

# Define the properties you want to retrieve, these are the general bitlocker properties
$searcher.PropertiesToLoad.Add("msFVE-RecoveryPassword")
$searcher.PropertiesToLoad.Add("msFVE-RecoveryGuid")
$searcher.PropertiesToLoad.Add("distinguishedName")
$searcher.PropertiesToLoad.Add("whenCreated")
# Perform the search
$results = $searcher.FindAll()

# Loop through each result and display the recovery password and associated computer
[System.Collections.Generic.List[object]]$BitlockerKeys = @() #lists are more efficient than arrays.
foreach ($result in $results) {
    $recoveryPassword = $result.Properties["msfve-recoverypassword"][0]
    $recoveryGuid = $result.Properties["msfve-recoveryguid"][0]
    $distinguishedName = $result.Properties["distinguishedname"][0]
    $computerName = ($distinguishedName -split ',')[1] -replace 'CN=', ''
    
    $BitlockerKeys.Add([PSCustomObject]@{
            RecoveryPassword = $recoveryPassword
            KeyId            = Convert-ADGuid -bytes $recoveryGuid
            ComputerName     = $computerName
            DN               = $distinguishedName
        })
}
#endregion

#region BitLocker AD CmdLets
#this one liner will find all keys in ad using the Ad Cmdlets.
Get-ADObject -Filter {objectclass -eq "msFVE-RecoveryInformation"} -Properties msFVE-RecoveryPassword, msFVE-RecoveryGuid | Select-Object @{Name="ComputerName";Expression={(Get-ADComputer -Identity "$(($_.DistinguishedName -split ',')[1..(($_.DistinguishedName -split ',').count -1)] -join ',')").Name}}, @{Name="RecoveryGuid";Expression={[guid]::new($_.'msFVE-RecoveryGuid')}}, msFVE-RecoveryPassword

