#region MBAM Query SOAP API Endpoint

# Define the MBAM SOAP API endpoint (replace with your actual service URL)
$mbamUrl = "https://ws-mbam.wetter.wetterssource.com/MBAMAdministrationService/AdministrationService.svc"
$PartialRecoveryKeyId = "16d58bb6"

# Construct the SOAP Envelope for GetRecoveryKeyIds request
$soapBody = @"
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <s:Header>
    <wsa:Action>http://tempuri.org/IAdministrationService/GetRecoveryKeyIds</wsa:Action>
    <wsa:To>$mbamUrl</wsa:To>
  </s:Header>
  <s:Body>
    <GetRecoveryKeyIds xmlns="http://tempuri.org/">
      <partialRecoveryKeyId>$PartialRecoveryKeyId</partialRecoveryKeyId>
      <reasonCode>Other</reasonCode>
    </GetRecoveryKeyIds>
  </s:Body>
</s:Envelope>
"@

# Perform the SOAP request using Invoke-WebRequest
$response = Invoke-WebRequest -Uri $mbamUrl -Method POST -Body $soapBody -ContentType "application/soap+xml" -UseBasicParsing -UseDefaultCredentials

# Output the Key Id String
$FullKeyId = ([xml]$response.Content).Envelope.Body.GetRecoveryKeyIdsResponse.GetRecoveryKeyIdsResult.string
$FullKeyId


#Now make a soap call with the full key ID to retrieve the key.
$soapBody = @"
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <s:Header>
    <wsa:Action>http://tempuri.org/IAdministrationService/GetRecoveryKey</wsa:Action>
    <wsa:To>$mbamUrl</wsa:To>
  </s:Header>
  <s:Body>
    <GetRecoveryKey xmlns="http://tempuri.org/">
      <recoveryKeyId>$FullKeyId</recoveryKeyId>
      <reasonCode>Other</reasonCode>
    </GetRecoveryKey>
  </s:Body>
</s:Envelope>
"@

# Perform the SOAP request using Invoke-WebRequest
$keyResponse = Invoke-WebRequest -Uri $mbamUrl -Method POST -Body $soapBody -ContentType "application/soap+xml" -UseBasicParsing -UseDefaultCredentials

([xml]$keyResponse.Content).Envelope.Body.GetRecoveryKeyResponse.GetRecoveryKeyResult
([xml]$keyResponse.Content).Envelope.Body.GetRecoveryKeyResponse.GetRecoveryKeyResult.RecoveryKey

#endregion MBAM SOAP

#region MBAM SQL

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
#endregion SQL Reader Function

#region Query MBAM SQL database
$SQLServer = "WS-MBAM.wetter.wetterssource.com"
$SQLDatabase = "MBAM Recovery and Hardware"

# A query that will join useful data from various tables into a single table.
$MbamQuery = @"
SELECT TOP (1000) M.[Id]
    ,M.[LastUpdateTime]
    ,[Name] 'ComputerName'
  ,VT.TypeName 'VolumeType'
  ,D.DomainName
  ,K.RecoveryKeyId
  ,K.RecoveryKey
  ,K.Disclosed
FROM [RecoveryAndHardwareCore].[Machines] M
left join [RecoveryAndHardwareCore].[Domains] D on D.Id = M.DomainId
left join [RecoveryAndHardwareCore].[Machines_Volumes] MV on MV.MachineId = M.Id
Left Join [RecoveryAndHardwareCore].[Keys] K on K.VolumeId = MV.VolumeId
Left Join [RecoveryAndHardwareCore].[Volumes] V on V.Id = MV.VolumeId
Left Join [RecoveryAndHardwareCore].[VolumeTypes] VT on VT.Id = V.VolumeTypeId
"@
Invoke-SqlDataReader -ServerInstance $SQLServer -Database $SQLDatabase -Query $MbamQuery

# Using the Stored procedure to find the Key Id and retrieve the Recovery key and flag the client to rotate keys.
$KeyToFind = '16d58bb6-1bb2-4fb2-9d0d-acb7a9472afd'
$RunStoredProcedure = "EXEC RecoveryAndHardwareRead.GetRecoveryKey @RecoveryKeyId='$KeyToFind', @Reason='Other'"
Invoke-SqlDataReader -ServerInstance $SQLServer -Database $SQLDatabase -Query $RunStoredProcedure
#endregion Query SQL

#endregion MBAM SQL