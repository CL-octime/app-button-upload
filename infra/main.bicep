//targetScope: Définit la portée du déploiement à un groupe de ressources.
targetScope = 'resourceGroup'
//environmentName: Paramètre pour le nom de l'environnement, utilisé pour générer un hash unique dans toutes les ressources.
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

//location: Paramètre pour la localisation principale de toutes les ressources.
@minLength(1)
@description('Primary location for all resources')
param location string
param appServicePlanName string = ''
param backendServiceName string = ''
param resourceGroupName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''
param searchServiceName string = ''
param searchServiceLocation string = ''

//searchServiceSkuName: Définit le niveau de service (SKU) pour le service de recherche. Les valeurs autorisées sont spécifiées.
@allowed([ 'free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2' ])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json
param searchServiceSemanticRankerLevel string // Set in main.parameters.json
var actualSearchServiceSemanticRankerLevel = (searchServiceSkuName == 'free') ? 'disabled' : searchServiceSemanticRankerLevel
param useSearchServiceKey bool = searchServiceSkuName == 'free'
param storageAccountName string = ''
param storageResourceGroupLocation string = location
param storageContainerName string = 'content'
param storageSkuName string // Set in main.parameters.json
param appServiceSkuName string // Set in main.parameters.json
//openAiHost: Paramètre pour définir l'hôte OpenAI, avec des valeurs autorisées 'azure' ou 'openai'.
@allowed([ 'azure', 'openai' ])
param openAiHost string // Set in main.parameters.json
param openAiServiceName string = ''
param useGPT4V bool = false

param keyVaultServiceName string = ''
param computerVisionSecretName string = 'computerVisionSecret'
param searchServiceSecretName string = 'searchServiceSecret'
@description('Location for the OpenAI resource group')
@allowed(['canadaeast', 'eastus', 'eastus2', 'francecentral', 'switzerlandnorth', 'uksouth', 'japaneast', 'northcentralus', 'australiaeast', 'swedencentral'])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiResourceGroupLocation string
param openAiSkuName string = 'S0'
param openAiApiKey string = ''
param openAiApiOrganization string = ''
param formRecognizerServiceName string = ''
param formRecognizerResourceGroupLocation string = location
param formRecognizerSkuName string = 'S0'
param computerVisionServiceName string = ''
param computerVisionResourceGroupLocation string = 'eastus' // Vision vectorize API is yet to be deployed globally
param computerVisionSkuName string = 'S1'
param chatGptDeploymentName string // Set in main.parameters.json
param chatGptDeploymentCapacity int = 30
param chatGpt4vDeploymentCapacity int = 10
param chatGptModelName string = (openAiHost == 'azure') ? 'gpt-35-turbo' : 'gpt-3.5-turbo'
param chatGptModelVersion string = '0613'
param embeddingDeploymentName string // Set in main.parameters.json
param embeddingDeploymentCapacity int = 30
param embeddingModelName string = 'text-embedding-ada-002'
param gpt4vModelName string = 'gpt-4'
param gpt4vDeploymentName string = 'gpt-4v'
param gpt4vModelVersion string = 'vision-preview'
param tenantId string = tenant().tenantId
param authTenantId string = ''
// Used for the optional login and document level access control system
param useAuthentication bool = false
param enforceAccessControl bool = false
param serverAppId string = ''
@secure()
param serverAppSecret string = ''
param clientAppId string = ''
@secure()
param clientAppSecret string = ''
// Used for optional CORS support for alternate frontends
param allowedOrigin string = '' // should start with https://, shouldn't end with a /
@description('Id of the user or app to assign application roles')
param principalId string = ''
@description('Use Application Insights for monitoring and performance tracing')
param useApplicationInsights bool = false
@description('Show options to use vector embeddings for searching in the app UI')
param useVectors bool = false
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var computerVisionName = !empty(computerVisionServiceName) ? computerVisionServiceName : '${abbrs.cognitiveServicesComputerVision}${resourceToken}'

var useKeyVault = useGPT4V || useSearchServiceKey
var tenantIdForAuth = !empty(authTenantId) ? authTenantId : tenantId
var authenticationIssuerUri = '${environment().authentication.loginEndpoint}${tenantIdForAuth}/v2.0'

// webapp: ressource qui crée la webapp et fait le deployement dans azure.
resource webapp 'Microsoft.Web/sites@2020-06-01' = {
  location: location
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.outputs.id
    siteConfig: {
      appSettings: [
        {
          name: 'EXAMPLE_SETTING'
          value: 'example_value'
        }
        // Ajout de vos paramètres OpenAI
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: '330e253bb8e7403eb202e2148092f17c'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: 'https://cog-wua5bqqiodftc.openai.azure.com/'
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: '330e253bb8e7403eb202e2148092f17c'
        }
      ]
      // D'autres configurations comme les versions de runtime, les certificats, etc.
    }
  }
}







// Organize resources in a resource group
/*resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

resource openAiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(openAiResourceGroupName)) {
  name: !empty(openAiResourceGroupName) ? openAiResourceGroupName : resourceGroup.name
}

resource formRecognizerResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(formRecognizerResourceGroupName)) {
  name: !empty(formRecognizerResourceGroupName) ? formRecognizerResourceGroupName : resourceGroup.name
}

resource computerVisionResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(computerVisionResourceGroupName)) {
  name: !empty(computerVisionResourceGroupName) ? computerVisionResourceGroupName : resourceGroup.name
}

resource searchServiceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(searchServiceResourceGroupName)) {
  name: !empty(searchServiceResourceGroupName) ? searchServiceResourceGroupName : resourceGroup.name
}

resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(storageResourceGroupName)) {
  name: !empty(storageResourceGroupName) ? storageResourceGroupName : resourceGroup.name
}

resource keyVaultResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(keyVaultResourceGroupName)) {
  name: !empty(keyVaultResourceGroupName) ? keyVaultResourceGroupName : resourceGroup.name
}*/

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = if (useApplicationInsights) {
  name: 'monitoring'
  
  params: {
    location: location
    tags: tags
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  }
}

//module applicationInsightsDashboard: Module conditionnel pour déployer un tableau de bord Application Insights si useApplicationInsights est vrai.
module applicationInsightsDashboard 'backend-dashboard.bicep' = if (useApplicationInsights) {
  name: 'application-insights-dashboard'
  
  params: {
    name: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
    location: location
    applicationInsightsName: useApplicationInsights ? monitoring.outputs.applicationInsightsName : ''
  }
}


// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: appServiceSkuName
      capacity: 1
    }
    kind: 'linux'
  }
}

// The application frontend
module webappcl 'core/host/appservice.bicep' = {
  name: 'web'
  
  params: {
    name: !empty(backendServiceName) ? backendServiceName : '${abbrs.webSitesAppService}backend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'webappcl' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.11'
    appCommandLine: 'python3 -m gunicorn main:app'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    allowedOrigins: [allowedOrigin]
    clientAppId: clientAppId
    serverAppId: serverAppId
    clientSecretSettingName: !empty(clientAppSecret) ? 'AZURE_CLIENT_APP_SECRET' : ''
    authenticationIssuerUri: authenticationIssuerUri
    use32BitWorkerProcess: appServiceSkuName == 'F1'
    alwaysOn: appServiceSkuName != 'F1'
    appSettings: {
      AZURE_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_STORAGE_CONTAINER: storageContainerName
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchService.outputs.name
      AZURE_SEARCH_SEMANTIC_RANKER: searchServiceSemanticRankerLevel
      AZURE_VISION_ENDPOINT: useGPT4V ? computerVision.outputs.endpoint : ''
      VISION_SECRET_NAME: useGPT4V ? computerVisionSecretName: ''
      SEARCH_SECRET_NAME: useSearchServiceKey ? searchServiceSecretName : ''
      AZURE_KEY_VAULT_NAME: useKeyVault ? keyVault.outputs.name : ''
      AZURE_SEARCH_QUERY_LANGUAGE: searchQueryLanguage
      AZURE_SEARCH_QUERY_SPELLER: searchQuerySpeller
      APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights ? monitoring.outputs.applicationInsightsConnectionString : ''
      // Shared by all OpenAI deployments
      OPENAI_HOST: openAiHost
      AZURE_OPENAI_EMB_MODEL_NAME: embeddingModelName
      AZURE_OPENAI_CHATGPT_MODEL: chatGptModelName
      AZURE_OPENAI_GPT4V_MODEL: gpt4vModelName
      // Specific to Azure OpenAI
      AZURE_OPENAI_SERVICE: openAiHost == 'azure' ? openAi.outputs.name : ''
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGptDeploymentName
      AZURE_OPENAI_EMB_DEPLOYMENT: embeddingDeploymentName
      AZURE_OPENAI_GPT4V_DEPLOYMENT: useGPT4V ? gpt4vDeploymentName : ''
      // Used only with non-Azure OpenAI deployments
      OPENAI_API_KEY: openAiApiKey
      OPENAI_ORGANIZATION: openAiApiOrganization
      // Optional login and document level access control system
      AZURE_USE_AUTHENTICATION: useAuthentication
      AZURE_ENFORCE_ACCESS_CONTROL: enforceAccessControl
      AZURE_SERVER_APP_ID: serverAppId
      AZURE_SERVER_APP_SECRET: serverAppSecret
      AZURE_CLIENT_APP_ID: clientAppId
      AZURE_CLIENT_APP_SECRET: clientAppSecret
      AZURE_TENANT_ID: tenantId
      AZURE_AUTH_TENANT_ID: tenantIdForAuth
      AZURE_AUTHENTICATION_ISSUER_URI: authenticationIssuerUri
      // CORS support, for frontends on other hosts
      ALLOWED_ORIGIN: allowedOrigin
      USE_VECTORS: useVectors
      USE_GPT4V: useGPT4V
    }
  }
}

var defaultOpenAiDeployments = [
  {
    name: chatGptDeploymentName
    model: {
      format: 'OpenAI'
      name: chatGptModelName
      version: chatGptModelVersion
    }
    sku: {
      name: 'Standard'
      capacity: chatGptDeploymentCapacity
    }
  }
  {
    name: embeddingDeploymentName
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: embeddingDeploymentCapacity
    }
  }
]

var openAiDeployments = concat(defaultOpenAiDeployments, useGPT4V ? [
    {
      name: gpt4vDeploymentName
      model: {
        format: 'OpenAI'
        name: gpt4vModelName
        version: gpt4vModelVersion
      }
      sku: {
        name: 'Standard'
        capacity: chatGpt4vDeploymentCapacity
      }
    }
  ] : [])


 //module openAi: Module conditionnel pour déployer des services cognitifs OpenAI si l'hôte est Azure. 
module openAi 'core/ai/cognitiveservices.bicep' = if (openAiHost == 'azure') {
  name: 'openai'
  
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiResourceGroupLocation
    tags: tags
    sku: {
      name: openAiSkuName
    }
    deployments: openAiDeployments
  }
}

module formRecognizer 'core/ai/cognitiveservices.bicep' = {
  name: 'formrecognizer'
  
  params: {
    name: !empty(formRecognizerServiceName) ? formRecognizerServiceName : '${abbrs.cognitiveServicesFormRecognizer}${resourceToken}'
    kind: 'FormRecognizer'
    location: formRecognizerResourceGroupLocation
    tags: tags
    sku: {
      name: formRecognizerSkuName
    }
  }
}

module computerVision 'core/ai/cognitiveservices.bicep' = if (useGPT4V) {
  name: 'computerVision'
  
  params: {
    name: computerVisionName
    kind: 'ComputerVision'
    location: computerVisionResourceGroupLocation
    tags: tags
    sku: {
      name: computerVisionSkuName
    }
  }
}


// module keyVault: Module conditionnel pour déployer Key Vault si useKeyVault est vrai.
// which is only used for GPT-4V.
module keyVault 'core/security/keyvault.bicep' = if (useKeyVault) {
  name: 'keyvault'
  
  params: {
    name: !empty(keyVaultServiceName) ? keyVaultServiceName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    principalId: principalId
  }
}

module webKVAccess 'core/security/keyvault-access.bicep' = if (useKeyVault) {
  name: 'web-keyvault-access'
  
  params: {
    keyVaultName: useKeyVault ? keyVault.outputs.name : ''
    principalId: webappcl.outputs.identityPrincipalId
  }
}

module secrets 'secrets.bicep' = if (useKeyVault) {
  name: 'secrets'
  
  params: {
    keyVaultName: useKeyVault ? keyVault.outputs.name : ''
    storeComputerVisionSecret: useGPT4V
    computerVisionId: useGPT4V ? computerVision.outputs.id : ''
    computerVisionSecretName: computerVisionSecretName
    storeSearchServiceSecret: useSearchServiceKey
    searchServiceId: useSearchServiceKey ? searchService.outputs.id : ''
    searchServiceSecretName: searchServiceSecretName
  }
}


module searchService 'core/search/search-services.bicep' = {
  name: 'search-service'
  
  params: {
    name: !empty(searchServiceName) ? searchServiceName : 'gptkb-${resourceToken}'
    location: !empty(searchServiceLocation) ? searchServiceLocation : location
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: searchServiceSkuName
    }
    semanticSearch: actualSearchServiceSemanticRankerLevel
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: storageResourceGroupLocation
    tags: tags
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    sku: {
      name: storageSkuName
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]
  }
}

// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = if (openAiHost == 'azure') {
  
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

/*module formRecognizerRoleUser 'core/security/role.bicep' = {
  
  name: 'formrecognizer-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: 'User'
  }
}*/

module storageRoleUser 'core/security/role.bicep' = {
  
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'User'
  }
}

/*module storageContribRoleUser 'core/security/role.bicep' = {
  
  name: 'storage-contribrole-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'User'
  }
}*/

// Only create if using managed identity (non-free tier)
module searchRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'User'
  }
}

/*module searchContribRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  
  name: 'search-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'User'
  }
}*/

/*module searchSvcContribRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  
  name: 'search-svccontrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'User'
  }
}*/

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = if (openAiHost == 'azure') {
  
  name: 'openai-role-backend'
  params: {
    principalId: webappcl.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleBackend 'core/security/role.bicep' = {
  
  name: 'storage-role-backend'
  params: {
    principalId: webappcl.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

// Used to issue search queries
// https://learn.microsoft.com/azure/search/search-security-rbac
module searchRoleBackend 'core/security/role.bicep' = if (!useSearchServiceKey) {
  
  name: 'search-role-backend'
  params: {
    principalId: webappcl.outputs.identityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}

// Used to read index definitions (required when using authentication)
// https://learn.microsoft.com/azure/search/search-security-rbac
module searchReaderRoleBackend 'core/security/role.bicep' = if (useAuthentication && !useSearchServiceKey) {
  
  name: 'search-reader-role-backend'
  params: {
    principalId: webappcl.outputs.identityPrincipalId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
  }
}



//output AZURE_LOCATION: Sortie qui fournit la localisation principale des ressources déployées.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
output AZURE_AUTH_TENANT_ID string = authTenantId
output AZURE_RESOURCE_GROUP string = resourceGroupName

// Shared by all OpenAI deployments
output OPENAI_HOST string = openAiHost
output AZURE_OPENAI_EMB_MODEL_NAME string = embeddingModelName
output AZURE_OPENAI_CHATGPT_MODEL string = chatGptModelName
output AZURE_OPENAI_GPT4V_MODEL string = gpt4vModelName

// Specific to Azure OpenAI
output AZURE_OPENAI_SERVICE string = (openAiHost == 'azure') ? openAi.outputs.name : ''
output AZURE_OPENAI_RESOURCE_GROUP string = (openAiHost == 'azure') ? resourceGroupName : ''
output AZURE_OPENAI_CHATGPT_DEPLOYMENT string = (openAiHost == 'azure') ? chatGptDeploymentName : ''
output AZURE_OPENAI_EMB_DEPLOYMENT string = (openAiHost == 'azure') ? embeddingDeploymentName : ''
output AZURE_OPENAI_GPT4V_DEPLOYMENT string = (openAiHost == 'azure') ? gpt4vDeploymentName : ''

// Used only with non-Azure OpenAI deployments
output OPENAI_API_KEY string = (openAiHost == 'openai') ? openAiApiKey : ''
output OPENAI_ORGANIZATION string = (openAiHost == 'openai') ? openAiApiOrganization : ''

output AZURE_VISION_ENDPOINT string = useGPT4V ? computerVision.outputs.endpoint : ''
output VISION_SECRET_NAME string = useGPT4V ? computerVisionSecretName : ''
output AZURE_KEY_VAULT_NAME string = useKeyVault ? keyVault.outputs.name : ''

output AZURE_FORMRECOGNIZER_SERVICE string = formRecognizer.outputs.name
output AZURE_FORMRECOGNIZER_RESOURCE_GROUP string = resourceGroupName

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchService.outputs.name
output AZURE_SEARCH_SECRET_NAME string = useSearchServiceKey ? searchServiceSecretName : ''
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SEARCH_SEMANTIC_RANKER string = actualSearchServiceSemanticRankerLevel

output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = resourceGroupName

output AZURE_USE_AUTHENTICATION bool = useAuthentication

//output BACKEND_URI: Sortie qui fournit l'URI du service backend déployé.
output BACKEND_URI string = webappcl.outputs.uri
