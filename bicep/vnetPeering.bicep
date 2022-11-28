@description('Required. Resource name.')
param name string

@description('Required. Source Virtual Network resource name.')
param fromName string

@description('Required. Destination Virtual Network resource Id.')
param toId string

@description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is false.')
param allowForwardedTraffic bool = false

@description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false.')
param allowGatewayTransit bool = false

@description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true.')
param allowVirtualNetworkAccess bool = true

@description('Optional. If we need to verify the provisioning state of the remote gateway. Default is true.')
param doNotVerifyRemoteGateways bool = true

@description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false.')
param useRemoteGateways bool = false

resource _ 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: fromName

  resource peering 'virtualNetworkPeerings' = {
    name: name
    properties: {
      allowForwardedTraffic: allowForwardedTraffic
      allowGatewayTransit: allowGatewayTransit
      allowVirtualNetworkAccess: allowVirtualNetworkAccess
      doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
      useRemoteGateways: useRemoteGateways
      remoteVirtualNetwork: {
        id: toId
      }
    }
  }
}
