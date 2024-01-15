$ErrorActionPreference = "Stop"
$SCRIPT_PATH = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Write-Host (Split-Path -Parent -Path 0)

$location = "eastus"
$resource_prefix = "byo"
$storage_account = "${resource_prefix}sa"
$resource_group = "${resource_prefix}-rg"
$application_name = "${resource_prefix}-app"
$deploy_name = "byodeploy"
$deploy_infra = $true
$deploy_app = $true
$ZipContainerName = If ($env:ZIP_CONTAINER) { $env:ZIP_CONTAINER } Else { "functions" }

# Template
$parameters_file = "main.parameters.json"
$template_file = "main.bicep"

# Login to Azure
az login --use-device-code
az account set -s "<Place_Your_Subscription_Here>"

if ($deploy_infra) {
    Write-Host "Create Resource Group"
    az group create -n $resource_group -l $location

    Write-Host "Deploy Resources"
    az deployment group create -g $resource_group --name $deploy_name `
                            --template-file $template_file `
                            --parameters $parameters_file `
                            --parameters deploymentNameId="${deploy_name}-1" resourceNamePrefix=$resource_prefix
}

if ($deploy_app) {
    Write-Host "deploy function app"
    Set-Location "$SCRIPT_PATH\..\Src\"
    Remove-Item -Recurse -Force bin\publish -ErrorAction SilentlyContinue
    dotnet publish CarDetectorFuncApp\CarDetectorApp.csproj -c Release -o bin\publish
    Write-Host "zipping function app solution"
    Set-Location bin\publish
    Compress-Archive -Path * -DestinationPath "..\..\func.zip"
    Set-Location "..\..\"
    Write-Host "uploading to Azure Functions"
    az functionapp deployment source config-zip -g $resource_group -n $application_name --src ./func.zip
}
