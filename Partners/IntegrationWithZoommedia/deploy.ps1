## REQUIRED PARAMETERS
# Syntax: ".\deploy.ps1 -videoindexerregion aaa -videoindexeraccount bbbbbbbbb -videoindexerkey xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -zoommediatoken yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy" -language nl-nl

# Video Indexer and Zoom Media keys
param (
    [string]$videoindexerregion,
    [string]$videoindexeraccount,
    [string]$videoindexerkey,
    [string]$videoindexerlanguage,
    [string]$zoommediatoken,
    [string]$zoommedialanguage
 )

# Resource location and naming
$location="westeurope"
$randomvalue=$(Get-Random)
$resourcegroup="rg" + $randomvalue
$storageaccountname="stor" + $randomvalue
$containername="uploads"
$storconnectionname="storconn" + $randomvalue
$videoconnectionname="videoconn" + $randomvalue
$logicappname="logic" + $randomvalue

# Creating Resource Group
New-AzResourceGroup -Name $resourcegroup -Location $location

# Creating Storage Account and Container
New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageaccountname -Location $location -SkuName Standard_LRS
Set-AzCurrentStorageAccount -StorageAccountName $storageaccountname -ResourceGroupName $resourceGroup
New-AzStorageContainer -Name $containername

# Retrieving Subscription ID
$subscriptionId = (Get-AzContext).Subscription.Id

# Retrieving Storage Account Key
$storageaccountkey = (Get-AzStorageAccountKey -ResourceGroupName $resourcegroup -Name $storageaccountname).Value[0]

# Creating API Connection and Logic App
New-AzResourceGroupDeployment -Name APIConnectionDeployment -ResourceGroupName $resourcegroup `
    -TemplateFile .\template.json `
    -subscriptionId $subscriptionId `
    -location $location `
    -storConnectionname $storConnectionname `
    -videoConnectionName $videoconnectionname `
    -logicapp_name $logicappname `
    -storageAccountName $storageaccountname `
    -storageAccountKey $storageaccountkey `
    -containerName $containername `
    -videoindexerregion $videoindexerregion `
    -videoindexeraccount $videoindexeraccount `
    -videoindexerkey $videoindexerkey `
    -videoindexerlanguage $videoindexerlanguage `
    -zoommediatoken $zoommediatoken `
    -zoommedialanguage $zoommedialanguage