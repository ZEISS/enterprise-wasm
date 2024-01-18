terraform output -raw kube_config > ~/.kube/config
$jsonOutput = terraform output -json script_vars | ConvertFrom-Json
$RESOURCE_GROUP_NAME = $jsonOutput.resource_group

$AZURE_CONTAINER_REGISTRY_NAME = (az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv)

while ($AZURE_CONTAINER_REGISTRY_NAME -eq $null)
{
  Write-Host "wait 30 seconds for resources & AAD auth to be available"
  Start-Sleep -Miliseconds 30000
  $AZURE_CONTAINER_REGISTRY_NAME = (az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv)
}

$AZURE_CONTAINER_REGISTRY_ENDPOINT = (az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv)
$APPINSIGHTS_ID = (az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Insights/components --query '[0].id' -o tsv) 
$INSTRUMENTATION_KEY = (az monitor app-insights component show --ids $APPINSIGHTS_ID --query instrumentationKey -o tsv)

# ---- install OpenTelemetry
$filePath = "./open-telemetry-collector-appinsights.yaml"
$yamlFile = (Get-Content -Path $filePath) -replace '<INSTRUMENTATION-KEY>', $INSTRUMENTATION_KEY
$yamlFile | kubectl apply -f -
kubectl apply -f ./collector-config.yaml