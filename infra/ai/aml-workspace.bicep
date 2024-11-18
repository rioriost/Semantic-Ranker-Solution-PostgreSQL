@description('Location for all resources.')
param location string

@description('Workspace name.')
param workspaceName string

@description('Endpoint name.')
param endpointName string

@description('Unique name for the Key Vault instance.')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Unique name for the Application Insights instance.')
param appInsightsName string = 'appi-${workspaceName}-${uniqueString(resourceGroup().id)}'

@description('Unique name for the Storage Account instance.')
param storageAccountName string = 'sa${uniqueString(resourceGroup().id)}'

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource amlWorkspace 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
  name: workspaceName
  location: location
  identity: {type: 'SystemAssigned'}
  properties: {
    description: 'Azure Machine Learning workspace'
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    storageAccount: storageAccount.id
  }
}

resource amlOnlineEndpoint 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-07-01-preview' = {
  name: endpointName
  location: location
  identity: {type: 'SystemAssigned'}
  parent: amlWorkspace
  properties: {
    authMode: 'Key'
    description: 'bge-v2-m3 reranker model endpoint'
    // For remaining properties, see OnlineEndpointProperties objects
  }
}

output AML_WORKSPACE_NAME string = amlWorkspace.name
