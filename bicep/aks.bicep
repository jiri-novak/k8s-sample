@description('Required. Resource name.')
param name string

@description('Required. Name of existing virtual network to deploy cluster.')
param vnetName string

@description('Required. Name of existing subnet for cluster.')
param subnetClusterName string

@description('Required. Name of existing subnet for ACI.')
param subnetAciName string

@description('Required. AppGW name.')
param appGwName string

@description('Optional. Resource location. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Optional. Name of system node pool. Default is \'sys\'.')
param systemPoolName string = 'sys'

@description('Optional. Name of user linux node pool. Default is \'lin\'.')
param userPoolNameLinux string = 'lin'

@description('Optional. Username to use for administrator for both Windows and Linux profiles. Default is \'azureuser\'.')
param profileAdminUsername string = 'azureuser'

@description('Optional. Override resource group name, used to deploy cluster node resources.')
param nodeResourceGroup string = 'MC_${resourceGroup().name}_${name}_${location}'

@description('Optional. Kubernetes version. Default is \'1.24.6\'.')
param kubernetesVersion string = '1.24.6'

@description('Required. Resource ID of the monitoring log analytics workspace.')
param logAnalyticsWorkspaceId string

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName

  resource subnetCluster 'subnets' existing = {
    name: subnetClusterName
  }

  resource subnetAci 'subnets' existing = {
    name: subnetAciName
  }
}

resource appGw 'Microsoft.Network/applicationGateways@2022-05-01' existing = {
  name: appGwName
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: '${name}-dns'
    agentPoolProfiles: [
      {
        name: systemPoolName
        count: 1
        vmSize: 'Standard_B2ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        maxPods: 30
        osType: 'Linux'
        mode: 'System'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: vnet::subnetCluster.id
        enableAutoScaling: false
        enableFIPS: false
        orchestratorVersion: kubernetesVersion
      }
      {
        name: userPoolNameLinux
        count: 1
        vmSize: 'Standard_B2ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        maxPods: 30
        osType: 'Linux'
        mode: 'User'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: vnet::subnetCluster.id
        enableAutoScaling: false
        enableFIPS: false
        orchestratorVersion: kubernetesVersion
      }
    ]
    linuxProfile: {
      adminUsername: profileAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyCo5YP0RITbTdRnNoNx4RoKJ4w8r+Mz07ujWC1HRhGjnZ5iPVRs7XSzhjfYxJBFbY991IpRPF36RseWGqH67YgVt7n7BaRXL33Co4LKzlflJw7lOU+M9XAhuVH7fv0/Q7sFyZas4IBfXWzQ9LCnOXj3RsWykz8oiHK/0WXT+h98U7qrzMiGwww81EfiE+8RENyxeuvbWqTtrQOL5Qbd7V/DpCSK/YHa99AS04skiZp8HWuCtFDp7cG7u/9XH/WgVIFyhdsdWDcFdfRRmtYvS66g4EPpAznaCdODIB/twic37us1ghm7KWX3E8Zix3siuHqr9BtTX4i/CWxV3JpvgL'
          }
        ]
      }
    }
    addonProfiles: {
      aciConnectorLinux: {
        enabled: true
        config: {
          SubnetName: vnet::subnetAci.name
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azurekeyvaultsecretsprovider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      ingressapplicationgateway: {
        enabled: true
        config: {
          applicationGatewayId: appGw.id
        }
      }
      httpapplicationrouting: {
        enabled: false
      }
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
    }
  }
}

output name string = aks.name
output id string = aks.id
output nodeResourceGroup string = nodeResourceGroup
