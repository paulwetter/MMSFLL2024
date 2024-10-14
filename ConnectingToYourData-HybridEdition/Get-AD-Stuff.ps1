$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.Filter = "(&(objectCategory=computer)(!(objectClass=msDS-GroupManagedServiceAccount))(!(objectClass=msDS-ManagedServiceAccount)))"
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

[System.Collections.Generic.List[object]]$computers = @()
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
    $enabled = ($computer.useraccountcontrol[0] -band 2) -ne 2
    $created = $computer.whencreated[0]
    $lastlogon = [DateTime]::FromFileTime($computer.lastlogon[0])
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
            pwdLastSet         = [DateTime]$computer.pwdlastset[0]
            accountDisabled    = $enabled
        }
    )
}
$computers |FT

function Convert-ADGuid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $bytes
    )
    ([guid]::new($bytes)).Guid
}

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

##Query for bitlocker keys:

# Define a searcher to query Active Directory
$searcher = New-Object DirectoryServices.DirectorySearcher

# Set the filter to search for BitLocker Recovery Information
$searcher.Filter = "(&(objectClass=msFVE-RecoveryInformation))"
$searcher.Filter = "(&(objectClass=msFVE-RecoveryInformation)(msFVE-RecoveryGuid=$specificGuid))"

# Define the properties you want to retrieve
$searcher.PropertiesToLoad.Add("msFVE-RecoveryPassword")
$searcher.PropertiesToLoad.Add("msFVE-RecoveryGuid")
$searcher.PropertiesToLoad.Add("distinguishedName")
$searcher.PropertiesToLoad.Add("whenCreated")
# Perform the search
$results = $searcher.FindAll()


#string recovery password
$results[0].Properties.'msfve-recoverypassword'[0]
$results[0].Properties.whencreated[0]

# Loop through each result and display the recovery password and associated computer
[System.Collections.Generic.List[object]]$BitlockerKeys = @()
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



Get-ADObject -Filter {objectclass -eq "msFVE-RecoveryInformation"} -Properties msFVE-RecoveryPassword, msFVE-RecoveryGuid | Select-Object @{Name="ComputerName";Expression={(Get-ADComputer -Identity "$(($_.DistinguishedName -split ',')[1..(($_.DistinguishedName -split ',').count -1)] -join ',')").Name}}, @{Name="RecoveryGuid";Expression={[guid]::new($_.'msFVE-RecoveryGuid')}}, msFVE-RecoveryPassword






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
            LastLogon              = [datetime]$comp.lastLogon
            lastLogonTimestamp     = [datetime]$comp.lastLogonTimestamp
            ObjectGUID             = $comp.ObjectGUID.Guid
            ObjectSid              = $comp.SID.Value
            CreatedDate            = $comp.whenCreated
            DistinguishedName      = $comp.distinguishedName
            userAccountControl     = $comp.userAccountControl
            pwdLastSet             = [DateTime]$comp.pwdLastSet
            Enabled                = $comp.Enabled
        })
}
