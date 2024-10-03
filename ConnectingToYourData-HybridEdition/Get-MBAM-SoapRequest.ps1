# Define the MBAM SOAP API endpoint (replace with your actual service URL)
$mbamUrl = "https://ws-mbam.wetter.wetterssource.com/MBAMAdministrationService/AdministrationService.svc"

# Construct the SOAP Envelope for GetRecoveryKeyIds request
$soapBody = @"
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <s:Header>
    <wsa:Action>http://tempuri.org/IAdministrationService/GetRecoveryKeyIds</wsa:Action>
    <wsa:To>$mbamUrl</wsa:To>
  </s:Header>
  <s:Body>
    <GetRecoveryKeyIds xmlns="http://tempuri.org/">
      <partialRecoveryKeyId>16d58bb6</partialRecoveryKeyId>
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