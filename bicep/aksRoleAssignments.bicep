@description('Required. AKS name.')
param aksName string

@description('Required. Name of the resource group with AKS resources.')
param aksNodeResourceGroup string

@description('Required. ACR name.')
param acrName string

@description('Required. KeyVault name.')
param keyVaultName string

@description('Required. Name of existing virtual network to deploy cluster.')
param vnetName string

@description('Required. Name of existing subnet for cluster.')
param subnetClusterName string

@description('Required. Name of existing subnet for ACI.')
param subnetAciName string

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrName
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' existing = {
  name: aksName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName

  resource subnetCluster 'subnets' existing = {
    name: subnetClusterName
  }

  resource subnetAci 'subnets' existing = {
    name: subnetAciName
  }
}


var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var networkContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(resourceGroup().id, aks.id, acrPullRoleDefinitionId)
  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRoleDefinitionId
  }
}

resource ingressapplicationgatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  scope: resourceGroup(aksNodeResourceGroup)
  name: 'ingressapplicationgateway-${aks.name}'
}

resource ingressapplicationgatewayIdentityAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(resourceGroup().id, ingressapplicationgatewayIdentity.id, contributorRoleDefinitionId)
  properties: {
    principalId: ingressapplicationgatewayIdentity.properties.principalId
    roleDefinitionId: contributorRoleDefinitionId
  }
}

resource aciconnectorlinuxIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  scope: resourceGroup(aksNodeResourceGroup)
  name: 'aciconnectorlinux-${aks.name}'
}

resource aciconnectorlinuxIdentityAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: vnet::subnetAci
  name: guid(vnet::subnetAci.id, aciconnectorlinuxIdentity.id, networkContributorRoleDefinitionId)
  properties: {
    principalId: aciconnectorlinuxIdentity.properties.principalId
    roleDefinitionId: networkContributorRoleDefinitionId
  }
}

resource azurekeyvaultsecretsproviderIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  scope: resourceGroup(aksNodeResourceGroup)
  name: 'azurekeyvaultsecretsprovider-${aks.name}'
}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: azurekeyvaultsecretsproviderIdentity.properties.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
          ]
          certificates: [
            'get'
          ]
          keys: [
            'get'
          ]
        }
      }
    ]
  }
}
