param([string] $accountResourceId)

$apiVersion = "2023-06-02-preview"
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['result'] = ''
$createResourcesUri = "https://management.azure.com/$accountResourceId/CreateExtensionDependencies?api-version=$apiVersion"
Write-Output "Creating dependent Cognitivie resource for account $accountResourceId"

$result = Invoke-AzRestMethod -Uri $createResourcesUri -Method Post

if ($result.StatusCode -ne [System.Net.HttpStatusCode]::Conflict -and $result.StatusCode -ne [System.Net.HttpStatusCode]::Created) {
    Write-Output "Could not get Cognitive resources data. Exiting."
    $resultJson = $result | ConvertFrom-Json
    $DeploymentScriptOutputs['result'] = $resultJson
    return
}


$DeploymentScriptOutputs['result'] = $accountResourceId
$getSecretsUri = "https://management.azure.com/${accountResourceId}/ListExtensionDependenciesData?api-version=${apiVersion}"
echo $getSecretsUri
Write-Output "Waiting to get Cognitive resources data"
$csResourcesData = Invoke-AzRestMethod -Uri $getSecretsUri -method post
$content = $csResourcesData.Content
$maxNumRetries = 8
while (($maxNumRetries -gt 0) -and ($content -Match "error")) {
    Write-Output "Waiting to get cognitive resources data"
    $csResourcesData = Invoke-AzRestMethod -Uri $getSecretsUri -method post
    $content = $csResourcesData.Content
    $maxNumRetries--
    Start-Sleep -Seconds 15
}
if ((($csResourcesData -Match "error") -or ($content -Match "error")) -and ($maxNumRetries -eq 0)) {
    $DeploymentScriptOutputs['result'] = $content
    return
} else {
    $resultJson = $content | ConvertFrom-Json
    $DeploymentScriptOutputs['speechCognitiveServicesEndpoint'] = $resultJson.speechCognitiveServicesEndpoint.ToString()
    $DeploymentScriptOutputs['translatorCognitiveServicesEndpoint'] = $resultJson.translatorCognitiveServicesEndpoint.ToString()
    $DeploymentScriptOutputs['ocrCognitiveServicesEndpoint'] = $resultJson.ocrCognitiveServicesEndpoint.ToString()
    $DeploymentScriptOutputs['speechCognitiveServicesPrimaryKey'] = $resultJson.speechCognitiveServicesPrimaryKey.ToString()
    $DeploymentScriptOutputs['translatorCognitiveServicesPrimaryKey'] = $resultJson.translatorCognitiveServicesPrimaryKey.ToString()
    $DeploymentScriptOutputs['ocrCognitiveServicesPrimaryKey'] = $resultJson.ocrCognitiveServicesPrimaryKey.ToString()
    $DeploymentScriptOutputs['result'] = "Got Cognitive resources data"
}