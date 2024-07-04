$rg="pe-ts-int-rg"
$peName="pe7"
$peConnectionName="pe7-connection"
$location="southafricanorth"
$resourceId="/subscriptions/24237b72-8546-4da5-b204-8c3cb76dd930/resourceGroups/pe-ts-int-rg/providers/Microsoft.VideoIndexer/accounts/pe-ts-int9"

## Az CLI Version
az network private-endpoint create `
  --resource-group $rg `
  --name $peName `
  --vnet-name 'pe-ts-int-vnet' `
  --subnet 'default' `
  --private-connection-resource-id  $resourceId `
  --group-ids 'account' `
  --connection-name $peConnectionName `
  --location $location