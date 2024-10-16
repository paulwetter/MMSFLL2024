# Define the SCCM Site Server and Site Code
$SCCMServer = "WS-CM1.wetter.wetterssource.com"
$SCCMSQLServer = "WS-CM1.wetter.wetterssource.com"
$SiteCode = "WS1"  # Replace with your SCCM site code
$CmDatabase = "CM_$SiteCode"

# Define the WMI namespace
$namespace = "ROOT\sms\site_$SiteCode"

# Query all devices (computers) from SCCM
$devices = Get-WmiObject -Namespace $namespace -Class SMS_R_System -ComputerName $SCCMServer

# Display the device names
$devices | Select-Object *

#convert a guid to a readable guid.
[guid]::new($devices[7].ObjectGUID).guid

#Combined Device Resource:


# Define the WMI namespace
$namespace = "ROOT\sms\site_$SiteCode"

# Query all devices (computers) from SCCM
$devices = Get-WmiObject -Namespace $namespace -Class CombinedDeviceResources -ComputerName $SCCMServer

# Display the device names
$devices | Select-Object *

##Admin Service

# Define the SCCM Admin Service URL
$AdminServiceUrl = "https://$SCCMServer/AdminService/"

# Define the endpoint for retrieving device information
$endpoint = "$AdminServiceUrl/wmi/SMS_R_System"

#Headers to send and return proper data type
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

# Send an HTTP GET request to the Admin Service
$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -UseDefaultCredentials


[guid]::new([System.Convert]::FromBase64String($response.value[7].ObjectGUID))

#region SQL Reader Function
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
#endregion SQL Reader

#region BitLocker
#it is important to query the stored procedure for BitLocker keys.  This is because it will mark the key is exposed and trigger a key rotation on the next check in.  This is the same behaviour as MBAM.
$BitlockerKeyId = '67bf7a26-acf7-4cd1-9f9a-148343be6830'
$Query = "EXEC RecoveryAndHardwareRead.GetRecoveryKey @RecoveryKeyId='$BitlockerKeyId', @Reason='Other'"
Invoke-SqlDataReader -ServerInstance $SCCMSQLServer -Database $CmDatabase -Query $Query
#endregion BitLocker

#region Export My Data

$CDRQuery = @'
SELECT [MachineID]
      ,[Name]
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
      ,[AADTenantID]
      ,[AADDeviceID]
      ,[SerialNumber]
      ,[PrimaryUser]
      ,[CurrentLogonUser]
      ,[LastLogonUser]
      ,[MACAddress]
      ,[SMBIOSGUID]
      ,[CoManaged]
      ,[BoundaryGroups]
  FROM [v_CombinedDeviceResources]
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
#$results | Export-Csv -Path
#Endregion Export