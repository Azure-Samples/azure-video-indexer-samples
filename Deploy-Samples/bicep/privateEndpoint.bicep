param location string = 'southafricanorth'
param privateEndpointName string
param privateLinkResource string 

var viZone = 'privatelink.api.videoindexer.ai'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'pe-ts-int-vnet'
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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/default'
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


