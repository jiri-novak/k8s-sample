@description('Required. Resource name.')
param name string

@description('Required. Underlying Log Analytics workspace resource name.')
param logAnalyticsName string

@description('Required. Existing environment Key Vault name.')
param keyVaultName string

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Optional. The workspace daily quota for ingestion.')
param dailyQuotaGb int = 5

@description('Optional. Number of days data will be retained for.')
@minValue(0)
@maxValue(730)
param retentionInDays int = 30

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    IngestionMode: 'LogAnalytics'
    SamplingPercentage: 50
    WorkspaceResourceId: logAnalytics.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

resource _ 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName

  resource _ 'secrets' = {
    name: 'ApplicationInsightsInstrumentationKey'
    properties: {
      contentType: 'text/plain'
      value: appInsights.properties.InstrumentationKey
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
