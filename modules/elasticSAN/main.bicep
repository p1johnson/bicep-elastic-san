@description('Elastic SAN name')
param elasticSanName string = 'elasticsan${uniqueString(resourceGroup().id)}'

@description('Location for the Elastic SAN')
param elasticSanLocation string = resourceGroup().location

@description('Availability zones for the elastic SAN')
param availabilityZones array = []

@description('Base size for the elastic SAN in TiB')
param baseSizeTiB int

@description('Additional size for the elastic SAN in TiB')
param extendedCapacitySizeTiB int

@description('The SKU name for the elastic SAN')
param skuName string
param volumeGroups array = []
param tags object

resource elasticSan 'Microsoft.ElasticSan/elasticSans@2021-11-20-preview' = {
  name: elasticSanName
  location: elasticSanLocation
  tags: (empty(tags) ? null : tags)
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

module volumeGroups_0_volumeGroups_volumeGroup './volumeGroup.bicep' = [for i in range(0, length(range(0, length(volumeGroups)))): {
  name: volumeGroups[range(0, length(volumeGroups))[i]].volumeGroupName
  params: {
    volumeGroupObject: volumeGroups[range(0, length(volumeGroups))[i]]
    parentElasticSanName: elasticSanName
  }
  dependsOn: [
    elasticSan
  ]
}]
