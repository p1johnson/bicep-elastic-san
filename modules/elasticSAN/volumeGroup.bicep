param volumeGroupObject object
param parentElasticSanName string

resource parentElasticSanName_volumeGroupObject_volumeGroup 'Microsoft.ElasticSan/elasticSans/volumegroups@2021-11-20-preview' = {
  name: '${parentElasticSanName}/${volumeGroupObject.volumeGroupName}'
  properties: {
    encryption: volumeGroupObject.encryptionType
    protocolType: volumeGroupObject.protocolType
    networkAcls: volumeGroupObject.networkAcls
  }
}

resource parentElasticSanName_volumeGroupObject_volumeGroupName_volumeGroupObject_volumes_0_volumeGroupObject_volumes_volume 'Microsoft.ElasticSan/elasticSans/volumegroups/volumes@2021-11-20-preview' = [for i in range(0, length(range(0, length(volumeGroupObject.volumes)))): {
  name: '${volumeGroupObject.volumes[range(0, length(volumeGroupObject.volumes))[i]].volumeName}'
  parent: parentElasticSanName_volumeGroupObject_volumeGroup
  properties: {
    sizeGiB: volumeGroupObject.volumes[range(0, length(volumeGroupObject.volumes))[i]].sizeGiB
  }
}]
