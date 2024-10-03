# Define the SCCM Site Server and Site Code
$SCCMServer = "WS-CM1.wetter.wetterssource.com"
$SiteCode = "WS1"  # Replace with your SCCM site code

# Define the WMI namespace
$namespace = "ROOT\sms\site_$SiteCode"

# Query all devices (computers) from SCCM
$devices = Get-WmiObject -Namespace $namespace -Class SMS_R_System -ComputerName $SCCMServer

# Display the device names
$devices | Select-Object *

[guid]::new($devices[7].ObjectGUID).guid




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