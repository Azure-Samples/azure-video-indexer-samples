param location string
param privateEndpointName string
param privateLinkResource string
param vnetName string 
var viZone = 'privatelink.api.videoindexer.ai'
param deployPrivateEndpoint bool

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (deployPrivateEndpoint) {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/default'
    }
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    manualPrivateLinkServiceConnections: [
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployPrivateEndpoint) {
  name: viZone
  location: 'global'
  properties: {}
}

resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = if (deployPrivateEndpoint) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: viZone
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
