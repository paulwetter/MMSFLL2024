$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.Filter = "(objectClass=computer)"
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
$searcher.PropertiesToLoad.Add("distinguishedName")
$results = $searcher.FindAll()

foreach ($result in $results) {
    $computer = $result.Properties
    [PSCustomObject]@{
        Name             = $computer.name
        OperatingSystem  = $computer.operatingSystem
        LastLogon        = $computer.lastLogon
    }
}

[DateTime]::FromFileTime($results[7].Properties.lastlogontimestamp[0])
$sidString = (New-Object System.Security.Principal.SecurityIdentifier($adObject.ObjectSid[0],0)).Value

function Convert-ADGuid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $bytes
    )
    [guid]::new($bytes)
}



# Define a searcher to query Active Directory
$searcher = New-Object DirectoryServices.DirectorySearcher

# Set the filter to search for BitLocker Recovery Information
$searcher.Filter = "(&(objectClass=msFVE-RecoveryInformation))"

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
foreach ($result in $results) {
    $recoveryPassword = $result.Properties["msfve-recoverypassword"]
    $recoveryGuid = $result.Properties["msfve-recoveryguid"]
    $distinguishedName = $result.Properties["distinguishedname"]
    
    Write-Host "Recovery Password: $recoveryPassword"
    Write-Host "Recovery GUID: $recoveryGuid"
    Write-Host "Distinguished Name: $distinguishedName"
    Write-Host "-------------------------------------------"
}



Get-ADObject -Filter {objectclass -eq "msFVE-RecoveryInformation"} -Properties msFVE-RecoveryPassword, msFVE-RecoveryGuid | Select-Object @{Name="ComputerName";Expression={(Get-ADComputer -Identity "$(($_.DistinguishedName -split ',')[1..(($_.DistinguishedName -split ',').count -1)] -join ',')").Name}}, @{Name="RecoveryGuid";Expression={[guid]::new($_.'msFVE-RecoveryGuid')}}, msFVE-RecoveryPassword
