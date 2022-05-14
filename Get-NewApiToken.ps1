# Set your server name
$Hostname = "server"
# Set your ApiToken (Executing the function below will invalidate this token)
$ApiToken = "Your-Api-Token"

Function Get-NewS1ApiToken {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "ApiToken $ApiToken")
    $headers.Add("Content-Type", "application/json")
    $url = "https://$Hostname.sentinelone.net/web/api/v2.1/users/generate-api-token"
    $req = Invoke-RestMethod -Uri $url -Method 'POST' -Headers $headers -Body $json
    return $req.data.token
}

# Store the results of the request in a variable
$NewToken = Get-NewS1ApiToken

Write-Host "Your new ApiToken is: $NewToken" -ForegroundColor Green

# This script is a proof of concept. It's good to quickly generate a new token ahead of the 6-month expiration interval.
# It will be better to adapt this function into a script or service you run to actively update this token and store it somewhere safe.
# You can even call this function prior to every API call so you have a fresh and secure token every time.
# Doing it this way ensures that you'll never have to manually regenerate a new API Token in the management console.

# If you're using an RMM (You probably are), then you should be able to store the result of this function in some kind of 
# protected environment variable or field in your RMM for other scripts to reference.

# It's the best way I've found to ensure that process is automatic, and because every renewal invalidates the prior key, it also ensures that if a key is somehow leaked,
# it won't be any good to whoever stole it.