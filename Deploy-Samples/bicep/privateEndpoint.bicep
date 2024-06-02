param location string 
param privateEndpointName string 
param privateLinkResource string 

var subnet = '/subscriptions/24237b72-8546-4da5-b204-8c3cb76dd930/resourceGroups/pe-ts-int-rg/providers/Microsoft.Network/virtualNetworks/pe-ts-int-vnet/subnets/default'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet
    }
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkResource
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}
