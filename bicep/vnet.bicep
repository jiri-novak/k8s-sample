@description('Required. Resource name')
param name string

@description('Required. Virtual Network ranges')
@minLength(1)
param addressPrefixes array

@description('Required. Virtual Network subnets')
param subnets array = []

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
      }
    }]
  }
}

output name string = vnet.name
output id string = vnet.id
