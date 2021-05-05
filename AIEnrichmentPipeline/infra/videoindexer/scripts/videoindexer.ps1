param([String]$type)

if ($ENV:debug_log) {
    Start-Transcript -Path "./videoindexer.$type.log"
}

# Terraform provider sends in current state
# as a json object to stdin
$stdin = $input
$location = $ENV:LOCATION
$apiKey = $ENV:API_KEY
$createJSON = $ENV:CREATE_JSON

$VIBaseUrl = "https://api.videoindexer.ai"
$headers = @{
    "Ocp-Apim-Subscription-Key" = "$apiKey"
}
$userTokenEndpoint = "$VIBaseUrl/Auth/trial/Users/me/AccessToken?allowEdit=true"
$accountTokenEndpoint = "$VIBaseUrl/Auth/$location/Accounts?generateAccessTokens=false&allowEdit=false"

function create {
    $createJSON | Test-json
    
    Write-Host  "Starting create"
    Write-Host  "Get User access token $userTokenEndpoint"

    $userTokenResponse = Invoke-WebRequest $userTokenEndpoint `
        -Headers $headers `
        -Method 'GET' `
        -ContentType 'application/json; charset=utf-8'

    # Strip the quotes from start and end of the quoted string.
    $userToken = $userTokenResponse.Content.Replace("`"","")
    $createUrl = "$VIBaseUrl/$location/Accounts?accessToken=$userToken"

    $response = Invoke-WebRequest $createUrl `
        -Headers $headers `
        -Method 'POST' `
        -ContentType 'application/json; charset=utf-8' `
        -Body $createJSON

    write-host $response

    $accountInstance = $response.Content | ConvertFrom-JSON 
    if (!$accountInstance) {
        Throw "Failed to get account instance. Creation failed. Review logs"
    }

    # Set this data as the input and call read
    # which will retieve the account and it's token
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Used by read func')]
    $stdin = $accountInstance | ConvertTo-Json
    read
}

function read {
    Write-Host  "Starting read"

    $account = $stdin | ConvertFrom-JSON
    if (!$account.id) {
        Throw "Failed to get a valid Video Indexer account ID from state: $input"
    }

    $accountsTokenResponse = Invoke-WebRequest $accountTokenEndpoint `
        -Headers $headers `
        -Method 'GET' `
        -ContentType 'application/json; charset=utf-8'

    $accountDetails = $accountsTokenResponse | ConvertFrom-JSON |  Where-Object { $_.id -eq $account.id }

    if (!$accountDetails) {
        Throw "Couldn't find account may have manually been deleted. If so remove the state with 'terraform state rm ....'"
    }

    $accountDetails | ConvertTo-Json | Write-Host
}

function update {
    Write-Host  "Starting update"
    throw "Update not implemented //Todo: https://api-portal.videoindexer.ai/docs/services/Operations/operations/Update-Paid-Account-Azure-Media-Services?&pattern=update"
}

function delete {
    Write-Host  "The resource doesn't support deleting an account - this action will noop. Manual delete is required to avoid accidental deletion of this account."
}

Switch ($type) {
    "create" { create }
    "read" { read }
    "update" { update }
    "delete" { delete }
}