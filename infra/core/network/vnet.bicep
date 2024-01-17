param location string
param name string
param tags object = {}

var addressPrefix = '10.0.0.0/16'

var subnets = [
  {
    name: 'app-subnet'
    properties: {
      addressPrefix:'10.0.0.0/24'
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled' 
    }
  }
  {
    name: 'database-subnet'
    properties: {
      addressPrefix:'10.0.1.0/24'
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: [
        {
          name: 'database-subnet-delegation'
          properties: {
            serviceName: 'Microsoft.DBforMySQL/flexibleServers'
          }
        }
      ]   
    }
  }
  {
    name: 'website-subnet'
    properties: {
      addressPrefix:'10.0.2.0/24'
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: [
        {
          name: 'website-subnet-delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]   
    }
  }  
]

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
  }
}

output subnets array = [for (name, i) in subnets :{
  subnets : vnet.properties.subnets[i]
}]

output subnetids array = [for (name, i) in subnets :{
  subnets : vnet.properties.subnets[i].id
}]


output id string = vnet.id
output name string = vnet.name

output appSubId string = vnet.properties.subnets[0].id
output dbSubId string = vnet.properties.subnets[1].id
output websiteSubId string = vnet.properties.subnets[2].id
