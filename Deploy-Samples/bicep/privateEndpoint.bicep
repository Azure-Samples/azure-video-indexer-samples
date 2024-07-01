param location string = 'southafricanorth'
param privateEndpointName string = 'e2'
param privateLinkResource string = '/subscriptions/24237b72-8546-4da5-b204-8c3cb76dd930/resourceGroups/pe-ts-int-rg/providers/Microsoft.VideoIndexer/accounts/pe-ts-int8'

var subnet = '/subscriptions/24237b72-8546-4da5-b204-8c3cb76dd930/resourceGroups/pe-ts-int-rg/providers/Microsoft.Network/virtualNetworks/pe-ts-int-vnet/subnets/default'
var viZone = 'privatelink.api.videoindexer.ai'

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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: viZone
  location: 'global'
  properties: {}
}

resource privateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'variables[\'viZone\']'
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', viZone)
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}


