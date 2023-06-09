targetScope = 'subscription'

param location string = 'uksouth'
param resourceGroupName string = 'rg-esan-demo'
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
param elasticSanName string = 'esan-demo'
param elasticSanAvailabilityZones array = [
  '1'
]
param elasticSanBaseSizeTiB int = 1
param elasticSanExtendedSizeTiB int = 0
param elasticSanSkuName string = 'Premium_LRS'
param volumeGroupName string = 'vg-esan-demo'
param volumeName string ='vol-esan-demo'
param volumeSizeGiB int = 512

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
    targetIqn: elasticSAN.outputs.targetIqn
    targetHostname: elasticSAN.outputs.targetPortalHostname
    targetPort: elasticSAN.outputs.targetPortalPort
  }
}

module elasticSAN 'modules/elasticSAN/main.bicep' = {
  scope: resourceGroup
  name: 'elasticSAN'
  params: {
    elasticSanName: elasticSanName
    elasticSanLocation: location
    availabilityZones: elasticSanAvailabilityZones
    baseSizeTiB: elasticSanBaseSizeTiB
    extendedCapacitySizeTiB: elasticSanExtendedSizeTiB
    skuName: elasticSanSkuName
    volumeGroupName: volumeGroupName
    subnetId: virtualNetwork.outputs.serverSubnetId
    volumeName: volumeName
    volumeSizeGiB: volumeSizeGiB
  }
}

//output targetIqn string = elasticSAN.outputs.targetIqn
//output targetPortalHostname string = elasticSAN.outputs.targetPortalHostname
//output targetPortalPort int = elasticSAN.outputs.targetPortalPort
