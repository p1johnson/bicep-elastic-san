@description('Elastic SAN name')
param elasticSanName string

@description('Location for the Elastic SAN')
param elasticSanLocation string = resourceGroup().location

@description('Availability zones for the elastic SAN')
param availabilityZones array = []

@description('Base size for the elastic SAN in TiB')
param baseSizeTiB int

@description('Additional size for the elastic SAN in TiB')
param extendedCapacitySizeTiB int

@description('The SKU name for the elastic SAN')
param skuName string = 'Premium_LRS'

param volumeGroupName string
param encryptionType string = 'EncryptionAtRestWithPlatformKey'
param protocolType string = 'iSCSI'
param subnetId string
param volumeName string
param volumeSizeGiB int
param tags object = {}


resource elasticSan 'Microsoft.ElasticSan/elasticSans@2021-11-20-preview' = {
  name: elasticSanName
  location: elasticSanLocation
  tags: tags
  properties: {
    availabilityZones: (empty(availabilityZones) ? null : availabilityZones)
    baseSizeTiB: baseSizeTiB
    extendedCapacitySizeTiB: extendedCapacitySizeTiB
    sku: {
      name: skuName
      tier: 'Premium'
    }
  }
}

resource volumeGroup 'Microsoft.ElasticSan/elasticSans/volumegroups@2021-11-20-preview' = {
  parent: elasticSan
  name: volumeGroupName
  tags: tags
  properties: {
    encryption: encryptionType
    protocolType: protocolType
    networkAcls: {
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: subnetId
        }
      ]
    }
  }
}

resource volume 'Microsoft.ElasticSan/elasticSans/volumegroups/volumes@2021-11-20-preview' = {
  parent: volumeGroup
  name: volumeName
  properties: {
    sizeGiB: volumeSizeGiB
  }
}

output targetIqn string = volume.properties.storageTarget.targetIqn
output targetPortalHostname string = volume.properties.storageTarget.targetPortalHostname
output targetPortalPort int = volume.properties.storageTarget.targetPortalPort
