targetScope = 'subscription'

param location string = 'uksouth'
param resourceGroupName string = 'rg-cis-elastic-san'
param virtualNetworkName string = 'vnet-esan-demo'
param virtualNetworkAddresses array = [
  '10.0.0.0/16'
]
param virtualNetworkDnsServers array = []
param serverSubnetName string = 'default'
param serverSubnetAddress string = '10.0.1.0/24'
param bastionSubnetAddress string = '10.0.0.192/26'
param bastionName string = 'bas-esan-demo'
param windowsServerName string = 'esandemo'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module virtualNetwork 'modules/virtualNetwork/azuredeploy.bicep' = {
  name: 'virtualNetwork'
  scope: resourceGroup
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddresses: virtualNetworkAddresses
    virtualNetworkDnsServers: virtualNetworkDnsServers
    serverSubnetName: serverSubnetName
    serverSubnetAddress: serverSubnetAddress
    bastionSubnetAddress: bastionSubnetAddress
  }
}

module azureBastion 'modules/azureBastion/azuredeploy.bicep' = {
  name: 'azureBastion'
  scope: resourceGroup
  params: {
    location: location
    bastionName: bastionName
    bastionSubnetId: virtualNetwork.outputs.bastionSubnetId
  }
}

module windowsServer 'modules/windowsServer/azuredeploy.bicep' = {
  name: 'windowsServer'
  scope: resourceGroup
  params: {
    location: location
    serverName: windowsServerName
    subnetId: virtualNetwork.outputs.serverSubnetId
  }
}

module elasticSAN 'modules/elasticSAN/main.bicep' = {
  scope: resourceGroup
  name: 'elasticSAN'
  params: {
    elasticSanName: 'esan-cis-test'
    elasticSanLocation: location
    availabilityZones: [
      '1'
    ]
    baseSizeTiB: 1
    extendedCapacitySizeTiB: 0
    skuName: 'Premium_LRS'
    volumeGroups: [
      {
        volumeGroupName: 'vg-cis-test'
        encryptionType: 'EncryptionAtRestWithPlatformKey'
        protocolType: 'iSCSI'
        networkAcls: {
          virtualNetworkRules: [
            {
              action: 'Allow'
              id: virtualNetwork.outputs.serverSubnetId
            }
          ]
        }
        volumes: [
          {
            volumeName: 'vol-cis-test'
            sizeGiB: '512'
          }
        ]
      }
    ]
    tags: {}
  }
}

output targets array = elasticSAN.outputs.targets
