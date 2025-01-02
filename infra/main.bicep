targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@description('Location for the OpenAI resource')
// Look for desired models on the availability table:
// https://learn.microsoft.com/azure/ai-services/openai/concepts/models#global-standard-model-availability
@allowed([
  'canadaeast'
  'eastus'
  'eastus2'
  'japaneast'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAILocation string

// Embedding model
@description('Name of the embedding model to deploy')
param embedModelName string // Set in main.parameters.json
@description('Name of the embedding model deployment')
param embedDeploymentName string // Set in main.parameters.json
@description('Dimensions of the embedding model')
param embedDimensions int // Set in main.parameters.json

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var prefix = '${toLower(name)}-${resourceToken}'
var tags = { 'azd-env-name': name }

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

var postgresServerName = '${prefix}-postgresql'
param postgresDatabaseName string // Set in main.parameters.json
param postgresAdminLoginName string // Set in main.parameters.json

param AMLworkspaceName string // Set in main.parameters.json
param AMLendpointName string // Set in main.parameters.json
param AMLlogAnalyticsWSName string // Set in main.parameters.json
param AMLdeploymentName string // Set in main.parameters.json

@secure()
param postgresAdminLoginPassword string


module AML 'ai/aml-workspace.bicep' = {
  name: 'aml'
  scope: resourceGroup
  params: {
    location: location
    workspaceName: AMLworkspaceName
    endpointName: AMLendpointName
    logAnalyticsWSName: AMLlogAnalyticsWSName
  }
}

module openAI 'ai/openai-service.bicep' = {
  name: 'openai'
  scope: resourceGroup
  params: {
    name: '${prefix}-openai'
    tags: tags
    location: openAILocation
    embedModelName: embedModelName
    embedDeploymentName: embedDeploymentName
  }
}

module postgresServer 'postgresql/postgresql-server.bicep' = {
  name: 'postgresql'
  scope: resourceGroup
  params: {
    serverName: postgresServerName
    location: location
    adminLoginName : postgresAdminLoginName
    adminLoginPassword: postgresAdminLoginPassword
    databaseName: postgresDatabaseName
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      autoGrow: 'Disabled'
      storageSizeGB: 32
      tier: 'P10'
    }
    version: '16'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP_NAME string = resourceGroup.name

output AZURE_AML_WORKSPACE_NAME string = AMLworkspaceName
output AZURE_AML_ENDPOINT_NAME string = AMLendpointName
output AZURE_AML_DEPLOYMENT_NAME string = AMLdeploymentName

output AZURE_OPENAI_EMBED_DEPLOYMENT string = embedDeploymentName
output AZURE_OPENAI_EMBED_MODEL string = embedModelName
output AZURE_OPENAI_EMBED_DIMENSIONS string = string(embedDimensions)

output AZURE_POSTGRES_HOST string = postgresServer.outputs.POSTGRES_DOMAIN_NAME
output AZURE_POSTGRES_USERNAME string = postgresAdminLoginName
output AZURE_POSTGRES_DB_NAME string = postgresDatabaseName
