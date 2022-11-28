@description('Required. Resource name.')
param name string

@description('Required. Flag indicating whether key vault already exists.')
param exists bool

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Optional. Flag indicating whether it should be possible to purge key vault. Default is false.')
param canPurge bool = false

@description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
@minValue(7)
@maxValue(90)
param daysSoftDelete int = 90

@description('Optional. Flag indicating whether public access to key vault should be enabled. Default is true.')
param enablePublicAccess bool = true

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = if (!exists) {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    accessPolicies: []
    enablePurgeProtection: canPurge ? null : true
    enableSoftDelete: !canPurge
    softDeleteRetentionInDays: daysSoftDelete
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

output name string = keyVault.name
output id string = keyVault.id
