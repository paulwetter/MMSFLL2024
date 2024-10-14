$ExportDirectory = "C:\Temp"
$CMExport = "$ExportDirectory\CMDevices.csv"
$AdExport = "$ExportDirectory\ADComputers.csv"
$AdUserExport = "$ExportDirectory\ADUsers.csv"
$IntuneExport = "$ExportDirectory\Intune.csv"

#region CM Export
$CDRQuery = @'
SELECT [ResourceID]
      ,[Name]
	  ,CAST(Object_GUID0 AS UNIQUEIDENTIFIER) AS 'ObjectGuid'
      ,[SMSID]
      ,[SiteCode]
      ,[Domain]
      ,[ClientVersion]
      ,[IsActive]
      ,[IsVirtualMachine]
      ,[IsApproved]
      ,[IsBlocked]
      ,[IsAlwaysInternet]
      ,[IsInternetEnabled]
      ,[ClientCertType]
      ,[UserName]
      ,[LastClientCheckTime]
      ,[ClientCheckPass]
      ,[ADSiteName]
      ,[UserDomainName]
      ,[ADLastLogonTime]
      ,[ClientActiveStatus]
      ,[LastStatusMessage]
      ,[LastPolicyRequest]
      ,[LastDDR]
      ,[LastHardwareScan]
      ,[LastSoftwareScan]
      ,[LastMPServerName]
      ,[LastActiveTime]
      ,[CP_Status]
      ,[CP_LatestProcessingAttempt]
      ,[CP_LastInstallationError]
      ,[DeviceOS]
      ,[DeviceOSBuild]
      ,[CNIsOnline]
      ,[CNLastOnlineTime]
      ,[CNLastOfflineTime]
      ,[CNAccessMP]
      ,[CNIsOnInternet]
      ,[ClientState]
      ,[Unknown]
      ,[CA_IsCompliant]
      ,[CA_ComplianceSetTime]
      ,[CA_ComplianceEvalTime]
      ,[CA_ErrorDetails]
      ,[CA_ErrorLocation]
      ,CDR.[AADTenantID]
      ,CDR.[AADDeviceID]
      ,CDR.[SerialNumber]
      ,[PrimaryUser]
      ,[CurrentLogonUser]
      ,[LastLogonUser]
      ,[MACAddress]
      ,[SMBIOSGUID]
      ,[CoManaged]
      ,[BoundaryGroups]
  FROM [v_CombinedDeviceResources] CDR
  JOIN [v_R_System] RS on RS.ResourceID = CDR.MachineID
  where ArchitectureKey != 2
'@
function Invoke-SqlDataReader {
 
    <#
    .SYNOPSIS
        Runs a select statement query against a SQL Server database.
     
    .DESCRIPTION
        Invoke-SqlDataReader is a PowerShell function that is designed to query
        a SQL Server database using a select statement without the need for the SQL
        PowerShell module or snap-in being installed.
     
    .PARAMETER ServerInstance
        The name of an instance of the SQL Server database engine. For default instances,
        only specify the server name: 'ServerName'. For named instances, use the format
        'ServerName\InstanceName'.
     
    .PARAMETER Database
        The name of the database to query on the specified SQL Server instance.
     
    .PARAMETER Query
        Specifies one Transact-SQL select statement query to be run.
     
    .PARAMETER QueryTimeout
        Specifies how long to wait until the SQL Query times out. default 300 Seconds
     
    .PARAMETER Credential
        SQL Authentication userid and password in the form of a credential object.
     
    .EXAMPLE
         Invoke-SqlDataReader -ServerInstance Server01 -Database Master -Query '
         select name, database_id, compatibility_level, recovery_model_desc from sys.databases'
     
    .EXAMPLE
         'select name, database_id, compatibility_level, recovery_model_desc from sys.databases' |
         Invoke-SqlDataReader -ServerInstance Server01 -Database Master
     
    .EXAMPLE
         'select name, database_id, compatibility_level, recovery_model_desc from sys.databases' |
         Invoke-SqlDataReader -ServerInstance Server01 -Database Master -Credential (Get-Credential)
     
    .INPUTS
        String
     
    .OUTPUTS
        DataRow
     
    .NOTES
        Author:  Mike F Robbins
        Website: http://mikefrobbins.com
        Twitter: @mikefrobbins
    #>
     
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory)]
        [string]$ServerInstance,
    
        [Parameter(Mandatory)]
        [string]$Database,
        
        [Parameter(Mandatory,
                    ValueFromPipeline)]
        [string]$Query,
        
        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$false)]
        [int]$QueryTimeout = 300,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    
    BEGIN {
        $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    
        if (-not($PSBoundParameters.Credential)) {
            $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
        }
        else {
            $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=False;"
            $userid= $Credential.UserName -replace '^.*\\|@.*$'
            ($password = $credential.Password).MakeReadOnly()
            $sqlCred = New-Object -TypeName System.Data.SqlClient.SqlCredential($userid, $password)
            $connection.Credential = $sqlCred
        }
    
        $connection.ConnectionString = $connectionString
        $ErrorActionPreference = 'Stop'
        
        try {
            $connection.Open()
            Write-Verbose -Message "Connection to the $($connection.Database) database on $($connection.DataSource) has been successfully opened."
        }
        catch {
            Write-Error -Message "An error has occurred. Error details: $($_.Exception.Message)"
        }
        
        $ErrorActionPreference = 'Continue'
        $command = $connection.CreateCommand()
        $command.CommandTimeout = $QueryTimeout
    }
    
    PROCESS {
        $command.CommandText = $Query
        $ErrorActionPreference = 'Stop'
    
        try {
            $result = $command.ExecuteReader()
        }
        catch {
            Write-Error -Message "An error has occured. Error Details: $($_.Exception.Message)"
        }
    
        $ErrorActionPreference = 'Continue'
    
        if ($result) {
            $dataTable = New-Object -TypeName System.Data.DataTable
            $dataTable.Load($result)
            $dataTable
        }
    }
    
    END {
        $connection.Close()
    }
    
}

$results = Invoke-SqlDataReader -ServerInstance $SCCMSQLServer -Database $CmDatabase -Query $CDRQuery
$results | Export-Csv -Path $CMExport -NoTypeInformation -Force
#Endregion CM Export

#region AD Export
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
            LastLogon              = [datetime]::FromFileTime($comp.lastLogon)
            lastLogonTimestamp     = [datetime]::FromFileTime($comp.lastLogonTimestamp)
            ObjectGUID             = $comp.ObjectGUID.Guid
            ObjectSid              = $comp.SID.Value
            CreatedDate            = $comp.whenCreated
            DistinguishedName      = $comp.distinguishedName
            userAccountControl     = $comp.userAccountControl
            pwdLastSet             = [DateTime]::FromFileTime($comp.pwdLastSet)
            Enabled                = $comp.Enabled
        })
}

$computers | Export-Csv -Path $AdExport -NoTypeInformation -Force
#endregion AD Export

#region AD Users
$users = Get-ADUser -Filter *
$users | Export-Csv -Path $AdUserExport -NoTypeInformation -Force

#endregion Ad Users

#region Intune Devices
$scopes = @(
    "User.Read.All"
    "BitlockerKey.Read.All"
    "DeviceManagementManagedDevices.Read.All"
)

Connect-MgGraph -Scopes $scopes -NoWelcome

$intuneAttributes = @(
    "AzureAdDeviceId"
    "AzureAdRegistered"
    "ComplianceState"
    "DeviceEnrollmentType"
    "DeviceName"
    "DeviceRegistrationState"
    "EnrolledDateTime"
    "TotalStorageSpaceInBytes"
    "FreeStorageSpaceInBytes"
    "Id"
    "IsEncrypted"
    "LastSyncDateTime"
    "ManagedDeviceOwnerType"
    "ManagementCertificateExpirationDate"
    "Manufacturer"
    "Model"
    "OSVersion"
    "OperatingSystem"
    "SerialNumber"
    "UserDisplayName"
    "UserId"
    "UserPrincipalName"    
)

$Devices=Get-MgDeviceManagementManagedDevice
$Devices | Select-Object -Property $intuneAttributes | Export-Csv -Path $IntuneExport -NoTypeInformation -Force
#endregion Intune Devices
