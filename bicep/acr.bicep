@description('Required. Resource name.')
param name string

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  location: location
  name: name
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true
  }
}

output name string = acr.name
output id string = acr.id
