@description('Location for all resources.')
param location string

param tags object = {}

@description('Unique name for the Azure OpenAI service.')
param name string

param embedModelName string
param embedDeploymentName string

@description('Creates an Azure OpenAI service.')
resource azureOpenAIService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    restore: false
  } 
}

@description('Creates an embedding deployment for the Azure OpenAI service.')
resource azureOpenAIEmbeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: embedDeploymentName
  parent: azureOpenAIService
  sku: {
    name: 'Standard'
    capacity: 300
  }
  properties: {
    model: {
      name: embedModelName
      format: 'OpenAI'
    }
  }
}

output service_name string = azureOpenAIService.name
output endpoint string = azureOpenAIService.properties.endpoint
