$rg="10spades-rg"
$peName="10spades-pe2"
$peConnectionName="10spades-pe2"
$location="southafricanorth"
$viName="10spades-vi"

az network private-endpoint-connection approve -g $rg -n $peName `
 --resource-name $viName `
 --type Microsoft.VideoIndexer/accountsA --description "Approved"

## Az CLI Version
# az network private-endpoint create `
#   --resource-group $rg `
#   --name $peName `
#   --vnet-name 'aci-vnet' `
#   --subnet 'pe-subnet' `
#   --private-connection-resource-id  $resourceId `
#   --group-ids 'blob' `
#   --connection-name $peConnectionName `
#   --manual-request y `
#   --location $location