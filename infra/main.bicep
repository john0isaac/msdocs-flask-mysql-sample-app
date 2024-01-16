targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

var mysqlServerName = '${prefix}-mysql'
var mysqlAdminUser = 'admin${uniqueString(resourceGroup.id)}'
var mysqlDatabaseName = 'app'
@secure()
@description('mysql Server administrator password')
param mysqlAdminPassword string
@secure()
param secretKey string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }
var prefix = '${name}-${resourceToken}'
var rgName = '${prefix}-rg'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: resourceGroup
  params: {
    name: '${take(replace(prefix, '-', ''), 17)}-vault'
    location: location
    tags: tags
    principalId: principalId
  }
}

var secrets = [
  {
    name: 'mysqlAdminUser'
    value: mysqlAdminUser
  }
  {
    name: 'mysqlAdminPassword'
    value: mysqlAdminPassword
  }
  {
    name: 'secretKey'
    value: secretKey
  }
]

@batchSize(1)
module keyVaultSecrets './core/security/keyvault-secret.bicep' = [for secret in secrets: {
  name: 'keyvault-secret-${secret.name}'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    name: secret.name
    secretValue: secret.value
  }
}]

module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    logAnalyticsName : '${prefix}-loganalytics'
    applicationInsightsName : '${prefix}-appinsights'
    applicationInsightsDashboardName: '${prefix}-appinsights-dashboard'
    location: location
    tags: tags
  }
}

module mysqlServer 'core/database/mysql/flexibleserver.bicep' = {
  name: 'mysql'
  scope: resourceGroup
  params: {
    name: mysqlServerName
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 20
    }
    version: '8.0.21'
    adminName: mysqlAdminUser
    adminPassword: mysqlAdminPassword
    databaseNames: [ mysqlDatabaseName ]
    allowAzureIPsFirewall: true
  }
}

module web 'core/host/appservice.bicep' = {
  name: 'appservice'
  scope: resourceGroup
  params: {
    name: '${prefix}-appservice'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    scmDoBuildDuringDeployment: true
    ftpsState: 'Disabled'
    managedIdentity: true
    appCommandLine: 'startup.sh'
    appSettings: {
      AZURE_MYSQL_HOST: mysqlServer.outputs.MYSQL_DOMAIN_NAME
      AZURE_MYSQL_NAME: mysqlDatabaseName
      AZURE_MYSQL_USER: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=mysqlAdminUser)'
      AZURE_MYSQL_PASSWORD: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=mysqlAdminPassword)'
      APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
      SECRET_KEY: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=secretKey)'
    }
  }
}

module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'serviceplan'
  scope: resourceGroup
  params: {
    name: '${prefix}-serviceplan'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
    reserved: true
  }
}

module webKeyVaultAccess 'core/security/keyvault-access.bicep' = {
  name: 'web-keyvault-access'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: web.outputs.identityPrincipalId
  }
}

output WEB_URI string = web.outputs.uri
output AZURE_LOCATION string = location
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
