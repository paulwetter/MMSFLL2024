# Define the SCCM Site Server and Site Code
$SCCMServer = "WS-CM1.wetter.wetterssource.com"
$SCCMSQLServer = "WS-CM1.wetter.wetterssource.com"
$SiteCode = "WS1"  # Replace with your SCCM site code
$CmDatabase = "CM_$SiteCode"

# Define the WMI namespace
$namespace = "ROOT\sms\site_$SiteCode"

#region Query all computers from CM with WMI
$devices = Get-WmiObject -Namespace $namespace -Class SMS_R_System -ComputerName $SCCMServer

# Display the device names
$devices | Select-Object *

#Some values need to be converted to readable text.  Some guids for example are stored as byte arrays.
$devices.foreach({
    [PSCustomObject]@{
        Name = $_.Name
        ObjectGuid = $_.ObjectGUID
    }
})

#You can convert the guid to a readable guid.
$devices.foreach({
    [PSCustomObject]@{
        Name = $_.Name
        ObjectGuid = [guid]::new($_.ObjectGUID).Guid
    }
})

#endregion WMI

#region Admin Service
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

#like WMI, you will get different values for things like the ObjectGuid.  You'll want to convert this from Base64 encoding.
$response.value.foreach({
    [PSCustomObject]@{
        Name = $_.Name
        ObjectGuid = $_.ObjectGUID
    }
})

#looking at the same results with a base64 decode and then converting to a readable guid from the byte array.
$response.value.foreach({
    [PSCustomObject]@{
        Name = $_.Name
        ObjectGuid = [guid]::new([System.Convert]::FromBase64String($_.ObjectGUID))
    }
})
#endregion Admin Service

#region SQL Reader Function - Function i found a long time ago to run sql queries using the built in sql functions.
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


#region SQL

$CDRQuery = @'
SELECT *
  FROM [v_R_System]
'@


$SQLresults = Invoke-SqlDataReader -ServerInstance $SCCMSQLServer -Database $CmDatabase -Query $CDRQuery
$SQLresults

#Like the others, we need to manipulate the guid...

#like WMI, you will get different values for things like the ObjectGuid.  You'll want to convert this from Base64 encoding.
$SQLresults.foreach({
    [PSCustomObject]@{
        Name = $_.Name0
        ObjectGuid = $_.Object_GUID0
    }
})

#looking at the same results with a base64 decode and then converting to a readable guid from the byte array.
$SQLresults.foreach({
    [PSCustomObject]@{
        Name = $_.Name0
        ObjectGuid = [guid]::new($_.Object_GUID0)
    }
})


#$SQLresults | Export-Csv -Path
#Endregion SQL


#region CM CmdLets

#Import CM Powershell module and change to the CM Site drive
Import-Module ConfigurationManager
$site = (Get-PSDrive | where {$_.Provider.Name -eq 'CMSite'}).Name
cd "$($site):"

#the closest thing in you CM cmdlets will not return the ObjectGuid.  ObjectGuid is useful for relating to other datasets.
$Devices = Get-CMDevice
$Devices.Name

$Devices.foreach({
    [PSCustomObject]@{
        Name = $_.Name
        AADDeviceID = $_.AADDeviceID
        ObjectGuid = $_.ObjectGUID
    }
})
#AADDeviceID will be useful for devices that are registered to MEID as the MEID Guid == AD ObjectGuid
#endregion


#region BitLocker retrieval.

#region BitLocker retrieval via key with stored procedure.
#it is important to note that querying the stored procedure for BitLocker keys will mark the key is exposed and trigger a key rotation on the next check in.  This is the same behaviour as MBAM.
$BitlockerKeyId = '67bf7a26-acf7-4cd1-9f9a-148343be6830'
$Query = "EXEC RecoveryAndHardwareRead.GetRecoveryKey @RecoveryKeyId='$BitlockerKeyId', @Reason='Other'"
Invoke-SqlDataReader -ServerInstance $SCCMSQLServer -Database $CmDatabase -Query $Query
#endregion stored procedure

#region BitLocker retrieval via Admin Service.

$ResourceID = '16777230'
$Device = Invoke-RestMethod -Uri "https://$($SCCMServer)/AdminService/v1.0/Device($($ResourceID))" -Method Get -UseDefaultCredentials

#Get the recovery key IDs
$KeyIDs = Invoke-RestMethod -Uri "https://$($SCCMServer)/AdminService/v1.0/Device($($ResourceID))/RecoveryKeys" -Method Get -UseDefaultCredentials

#Loop through the Ids and return the Recovery Keys
$KeyIDs.value | ForEach-Object {
    $Body = @{RecoveryKeyId = $_.RecoveryKeyId} | ConvertTo-Json
    $RecoveryKey = Invoke-RestMethod -Uri "https://$($SCCMServer)/AdminService/v1.0/Device($($ResourceID))/AdminService.GetRecoveryKeyValue" -Method Post -Body $Body -UseDefaultCredentials -ContentType "application/json" 
    [PSCustomObject]@{
        KeyId       = $_.RecoveryKeyId
        RecoveryKey = $RecoveryKey.value
    }
}
#endregion BitLocker retrieval via Admin Service 

#endregion BitLocker

