targetScope = 'subscription'

@description('Required. Flag indicating whether key vault already exists.')
param keyVaultExists bool = false

@description('Required. Flag indicating whether AKS already exists.')
param appGwExists bool = false

@description('Optional. Resource Group location. Default is westeurope.')
param location string = 'westeurope'

@description('Optional. Resource Group name. Default is samplek8s.')
param name string = 'samplek8s'

@description('Optional. Resources suffix. Default is samplek8s.')
param suffix string = 'samplek8s'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
}

module acr './acr.bicep' = {
  scope: rg
  name: 'acr'
  params: {
    name: 'acr${suffix}'
  }
}

module keyVault './keyvault.bicep' = {
  scope: rg
  name: 'keyvault'
  params: {
    name: 'keyvault${suffix}'
    exists: keyVaultExists
  }
}

var aksSubnetDefault = 'default'
var aksSubnetVirtualNodes = 'virtual-node-aci'

module aksVnet './vnet.bicep' = {
  scope: rg
  name: 'vnet-aks'
  params: {
    name: 'vnetaks${suffix}'
    addressPrefixes: [ '10.240.0.0/15' ]
    subnets: [
      {
        name: aksSubnetDefault
        addressPrefix: '10.240.0.0/16'
      }
      {
        name: aksSubnetVirtualNodes
        addressPrefix: '10.241.0.0/16'
        delegations: [
          {
            name: 'Microsoft.ContainerInstance.containerGroups'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
      }
    ]
  }
}

var appGwSubnetDefault = 'default'

module appGwVnet './vnet.bicep' = {
  scope: rg
  name: 'vnet-appgw'
  params: {
    name: 'vnetappgw${suffix}'
    addressPrefixes: [ '10.0.0.0/16' ]
    subnets: [
      {
        name: appGwSubnetDefault
        addressPrefix: '10.0.0.0/24'
      }
    ]
  }
}

module aks2AppGwPeering './vnetPeering.bicep' = {
  scope: rg
  name: 'vnet-peering-aks-2-appgw'
  params: {
    fromName: aksVnet.outputs.name
    name: 'aks-2-appgw'
    toId: appGwVnet.outputs.id
  }
}

module appGw2AksPeering './vnetPeering.bicep' = {
  scope: rg
  name: 'vnet-peering-appgw-2-aks'
  params: {
    fromName: appGwVnet.outputs.name
    name: 'appgw-2-aks'
    toId: aksVnet.outputs.id
  }
}

module appgw './appgw.bicep' = {
  scope: rg
  name: 'appgw'
  params: {
    name: 'appgw${suffix}'
    vnetName: appGwVnet.outputs.name
    subnetName: appGwSubnetDefault
    exists: appGwExists
  }
}

module appInsights 'appinsights.bicep' = {
  scope: rg
  name: 'appinsights'
  params: {
    name: 'ai${suffix}'
    logAnalyticsName: 'law${suffix}'
    keyVaultName: keyVault.outputs.name
  }
}

module aks './aks.bicep' = {
  scope: rg
  name: 'aks'
  params: {
    name: 'aks${suffix}'
    vnetName: aksVnet.outputs.name
    subnetClusterName: aksSubnetDefault
    subnetAciName: aksSubnetVirtualNodes
    appGwName: appgw.outputs.name
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
  }
}

module aksRoleAssignments './aksRoleAssignments.bicep' = {
  scope: rg
  name: 'aks-role-assignments'
  params: {
    acrName: acr.outputs.name
    aksName:  aks.outputs.name
    aksNodeResourceGroup: aks.outputs.nodeResourceGroup
    keyVaultName: keyVault.outputs.name
    vnetName: aksVnet.outputs.name
    subnetClusterName: aksSubnetDefault
    subnetAciName: aksSubnetVirtualNodes
  }
}
