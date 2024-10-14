#Getting a token with MGGraph
$Parameters = @{
    Method = "GET"
    URI = "/v1.0/me"
    OutputType = "HttpResponseMessage"
}
$Response = Invoke-GraphRequest @Parameters
$token = $Response.RequestMessage.Headers.Authorization.Parameter



$URL = "https://graph.microsoft.com/beta/deviceManagement/manageddevices(`'b52ebed7-3c82-418a-ae53-6b97bdc6240f`')"

$URL = 'https://graph.microsoft.com/beta/deviceManagement/manageddevices/?$top=5'

$token = "eyJ0eXAiOiJKV1QiLCJub25jZSI6ImJldnVJZU55RlNqeGduNXFlS2lGNXltRTA0RG9TLVUzbmVKMWJ2anhSM00iLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1jN2wzSXo5M2c3dXdnTmVFbW13X1dZR1BrbyIsImtpZCI6Ik1jN2wzSXo5M2c3dXdnTmVFbW13X1dZR1BrbyJ9.eyJhdWQiOiJodHRwczovL2dyYXBoLm1pY3Jvc29mdC5jb20vIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvNzM4N2Y4NmUtMGExNi00YmZlLTg0ZTMtNzUyZWUxMWFmYzJiLyIsImlhdCI6MTcyODUzNzkzOCwibmJmIjoxNzI4NTM3OTM4LCJleHAiOjE3Mjg1NDMwMTEsImFjY3QiOjAsImFjciI6IjEiLCJhaW8iOiJBVFFBeS84WUFBQUFZQ3NmQkMwUjQ3Ti83Q3krc0tpZWtwMUNydlpLM1NsUDQyWWF2czBydVZ2M29pNU5sTTg5OTVKbWVKTExHVzdwIiwiYW1yIjpbInB3ZCJdLCJhcHBfZGlzcGxheW5hbWUiOiJNaWNyb3NvZnQgSW50dW5lIHBvcnRhbCBleHRlbnNpb24iLCJhcHBpZCI6IjU5MjZmYzhlLTMwNGUtNGY1OS04YmVkLTU4Y2E5N2NjMzlhNCIsImFwcGlkYWNyIjoiMiIsImNvbnRyb2xzIjpbImNhX2VuZiJdLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIyMDguMTA3LjIzOS4xODciLCJuYW1lIjoiTU1TIiwib2lkIjoiYTQyYzgwOTgtMzkzMy00MWU1LTljNzgtMDAyZjdlNDNiY2VjIiwicGxhdGYiOiIzIiwicHVpZCI6IjEwMDMyMDAzRDVFOUQyQUYiLCJyaCI6IjAuQVdNQmJ2aUhjeFlLX2t1RTQzVXU0UnI4S3dNQUFBQUFBQUFBd0FBQUFBQUFBQUJqQVRJLiIsInNjcCI6IkNsb3VkUEMuUmVhZC5BbGwgQ2xvdWRQQy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRBcHBzLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudENvbmZpZ3VyYXRpb24uUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50TWFuYWdlZERldmljZXMuUHJpdmlsZWdlZE9wZXJhdGlvbnMuQWxsIERldmljZU1hbmFnZW1lbnRNYW5hZ2VkRGV2aWNlcy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRSQkFDLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudFNlcnZpY2VDb25maWd1cmF0aW9uLlJlYWRXcml0ZS5BbGwgRGlyZWN0b3J5LkFjY2Vzc0FzVXNlci5BbGwgZW1haWwgb3BlbmlkIHByb2ZpbGUgU2l0ZXMuUmVhZC5BbGwiLCJzdWIiOiJ1SFZQaWNOWHpXcG8zVmVfYUJSWjNyajRUNjludEpqd1h4b3llUEVKQXRVIiwidGVuYW50X3JlZ2lvbl9zY29wZSI6Ik5BIiwidGlkIjoiNzM4N2Y4NmUtMGExNi00YmZlLTg0ZTMtNzUyZWUxMWFmYzJiIiwidW5pcXVlX25hbWUiOiJtbXNAd2V0dGVyc3NvdXJjZW1tc291dGxvb2sub25taWNyb3NvZnQuY29tIiwidXBuIjoibW1zQHdldHRlcnNzb3VyY2VtbXNvdXRsb29rLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6InZveUpnUkdVYTBtbW9nZUFsMGdZQVEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjNhMmM2MmRiLTUzMTgtNDIwZC04ZDc0LTIzYWZmZWU1ZDlkNSIsIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfY2MiOlsiY3AxIl0sInhtc19pZHJlbCI6IjEgNCIsInhtc19zdCI6eyJzdWIiOiI1OWFGcktkc1BrRkU1ZEF4SkNEczVLQk9mQkE4a2FiS2pucFhnZEpuQzdjIn0sInhtc190Y2R0IjoxNzI3MjM0Nzk3fQ.dPzdZ6CInGRznF4ai1Glc6S1awhyipidFlP41IAOEkDRPxrayTzmL_UE9ph9zB5UcsnsWgTmU0ZaVm2KGrz28_1JHYBdB_tkZpfQUWNQ2oh_jVtr8dyo-ZKmPRrYBB-etb2m1Ay2RiU02wLmfYHlfQbUy3C7ecYeTl-AVGaXN-D7Em3jfflysgXZ9xHS8_s5Od5aSk4MiqQaohaReQ_SFvjbnV5PkioVGLZWAJptRT5xxVDQHWLxv20h4sSYmhoaJEKLcYfB6-WnkDn_YY_t6nURiS5142oBO06w9Ed7_o0MsI9dGBc-xPpyJJxwnmyOSQ28zyZ37sGMT0i6GW_pUw"
$header = @{
    'Authorization' = "Bearer $token"
}

$result = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $URL -Headers $header



# Variables for paging test.   
$uri = 'https://graph.microsoft.com/beta/deviceManagement/manageddevices/?$top=5' # Graph API endpoint for devices limited to 5 per page (computers)
$token = "eyJ0eXAiOiJKV1QiLCJub25jZSI6ImJldnVJZU55RlNqeGduNXFlS2lGNXltRTA0RG9TLVUzbmVKMWJ2anhSM00iLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1jN2wzSXo5M2c3dXdnTmVFbW13X1dZR1BrbyIsImtpZCI6Ik1jN2wzSXo5M2c3dXdnTmVFbW13X1dZR1BrbyJ9.eyJhdWQiOiJodHRwczovL2dyYXBoLm1pY3Jvc29mdC5jb20vIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvNzM4N2Y4NmUtMGExNi00YmZlLTg0ZTMtNzUyZWUxMWFmYzJiLyIsImlhdCI6MTcyODUzNzkzOCwibmJmIjoxNzI4NTM3OTM4LCJleHAiOjE3Mjg1NDMwMTEsImFjY3QiOjAsImFjciI6IjEiLCJhaW8iOiJBVFFBeS84WUFBQUFZQ3NmQkMwUjQ3Ti83Q3krc0tpZWtwMUNydlpLM1NsUDQyWWF2czBydVZ2M29pNU5sTTg5OTVKbWVKTExHVzdwIiwiYW1yIjpbInB3ZCJdLCJhcHBfZGlzcGxheW5hbWUiOiJNaWNyb3NvZnQgSW50dW5lIHBvcnRhbCBleHRlbnNpb24iLCJhcHBpZCI6IjU5MjZmYzhlLTMwNGUtNGY1OS04YmVkLTU4Y2E5N2NjMzlhNCIsImFwcGlkYWNyIjoiMiIsImNvbnRyb2xzIjpbImNhX2VuZiJdLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIyMDguMTA3LjIzOS4xODciLCJuYW1lIjoiTU1TIiwib2lkIjoiYTQyYzgwOTgtMzkzMy00MWU1LTljNzgtMDAyZjdlNDNiY2VjIiwicGxhdGYiOiIzIiwicHVpZCI6IjEwMDMyMDAzRDVFOUQyQUYiLCJyaCI6IjAuQVdNQmJ2aUhjeFlLX2t1RTQzVXU0UnI4S3dNQUFBQUFBQUFBd0FBQUFBQUFBQUJqQVRJLiIsInNjcCI6IkNsb3VkUEMuUmVhZC5BbGwgQ2xvdWRQQy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRBcHBzLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudENvbmZpZ3VyYXRpb24uUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50TWFuYWdlZERldmljZXMuUHJpdmlsZWdlZE9wZXJhdGlvbnMuQWxsIERldmljZU1hbmFnZW1lbnRNYW5hZ2VkRGV2aWNlcy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRSQkFDLlJlYWRXcml0ZS5BbGwgRGV2aWNlTWFuYWdlbWVudFNlcnZpY2VDb25maWd1cmF0aW9uLlJlYWRXcml0ZS5BbGwgRGlyZWN0b3J5LkFjY2Vzc0FzVXNlci5BbGwgZW1haWwgb3BlbmlkIHByb2ZpbGUgU2l0ZXMuUmVhZC5BbGwiLCJzdWIiOiJ1SFZQaWNOWHpXcG8zVmVfYUJSWjNyajRUNjludEpqd1h4b3llUEVKQXRVIiwidGVuYW50X3JlZ2lvbl9zY29wZSI6Ik5BIiwidGlkIjoiNzM4N2Y4NmUtMGExNi00YmZlLTg0ZTMtNzUyZWUxMWFmYzJiIiwidW5pcXVlX25hbWUiOiJtbXNAd2V0dGVyc3NvdXJjZW1tc291dGxvb2sub25taWNyb3NvZnQuY29tIiwidXBuIjoibW1zQHdldHRlcnNzb3VyY2VtbXNvdXRsb29rLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6InZveUpnUkdVYTBtbW9nZUFsMGdZQVEiLCJ2ZXIiOiIxLjAiLCJ3aWRzIjpbIjNhMmM2MmRiLTUzMTgtNDIwZC04ZDc0LTIzYWZmZWU1ZDlkNSIsIjYyZTkwMzk0LTY5ZjUtNDIzNy05MTkwLTAxMjE3NzE0NWUxMCIsImI3OWZiZjRkLTNlZjktNDY4OS04MTQzLTc2YjE5NGU4NTUwOSJdLCJ4bXNfY2MiOlsiY3AxIl0sInhtc19pZHJlbCI6IjEgNCIsInhtc19zdCI6eyJzdWIiOiI1OWFGcktkc1BrRkU1ZEF4SkNEczVLQk9mQkE4a2FiS2pucFhnZEpuQzdjIn0sInhtc190Y2R0IjoxNzI3MjM0Nzk3fQ.dPzdZ6CInGRznF4ai1Glc6S1awhyipidFlP41IAOEkDRPxrayTzmL_UE9ph9zB5UcsnsWgTmU0ZaVm2KGrz28_1JHYBdB_tkZpfQUWNQ2oh_jVtr8dyo-ZKmPRrYBB-etb2m1Ay2RiU02wLmfYHlfQbUy3C7ecYeTl-AVGaXN-D7Em3jfflysgXZ9xHS8_s5Od5aSk4MiqQaohaReQ_SFvjbnV5PkioVGLZWAJptRT5xxVDQHWLxv20h4sSYmhoaJEKLcYfB6-WnkDn_YY_t6nURiS5142oBO06w9Ed7_o0MsI9dGBc-xPpyJJxwnmyOSQ28zyZ37sGMT0i6GW_pUw"

# Function to query Graph API and handle pagination
function Get-AllGraphResults {
    param (
        [string]$initialUri,
        [string]$bearerToken
    )

#    [System.Collections.Generic.List[PSObject]]$results = @()  # List to store all query results
    $results = [System.Collections.Generic.List[PSObject]]::new()
    $nextLink = $initialUri
    $header = @{
        'Authorization' = "Bearer $token"
    }    

    while ($nextLink) {
        # Make the API request
        $response = Invoke-RestMethod -Uri $nextLink -Method Get -Headers $header

        # Append current results
        foreach ($r in $response.value) {
            $results.Add($r)
        }

        # Check if there's a next page (pagination)
        if ($response.'@odata.nextLink') {
            $nextLink = $response.'@odata.nextLink'  # Set the URI for the next page
        } else {
            $nextLink = $null  # No more pages
        }
    }

    return $results
}

# Call the function to get all devices (computers)
$allComputers = Get-AllGraphResults -initialUri $uri -bearerToken $token

# Output the result
$allComputers

$scopes = @(
    "User.Read.All"
    "BitlockerKey.Read.All"
    "DeviceManagementManagedDevices.Read.All"
)

Connect-MgGraph -Scopes $scopes -NoWelcome
$inDevices=Get-MgDeviceManagementManagedDevice
$BitlockerKeys = Get-MgInformationProtectionBitlockerRecoveryKey


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
