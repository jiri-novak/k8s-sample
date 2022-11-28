@description('Required. Resource name.')
param name string

@description('Required. Vnet name.')
param vnetName string

@description('Required. Subnet name.')
param subnetName string

@description('Required. Flag indicating whether app gw already exists.')
param exists bool

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

resource appGwPublicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'publicip${name}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

var publicFrontendIp = 'appGwPublicFrontendIp'
var port80 = 'port_80'
var port443 = 'port_443'
var backendPool = 'myBackendPool'
var httpSetting = 'myHTTPSetting'
var listenerHttp = 'myListenerHttp'

resource appGw 'Microsoft.Network/applicationGateways@2021-05-01' = if (!exists) {
  name: name
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: publicFrontendIp
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: port80
        properties: {
          port: 80
        }
      }
      {
        name: port443
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'myBackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: httpSetting
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: listenerHttp
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, publicFrontendIp)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, port80)
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, listenerHttp)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, backendPool)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, httpSetting)
          }
        }
      }
    ]
  }
}

output name string = appGw.name
output id string = appGw.id
