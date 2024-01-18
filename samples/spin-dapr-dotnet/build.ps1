$TARGET_INFRA_FOLDER = "../../infra/aks-dotnet-dapr"
$JSON_OUTPUT = (terraform output --state=$TARGET_INFRA_FOLDER/terraform.tfstate --json script_vars) | ConvertFrom-Json
$RESOURCE_GROUP_NAME = $JSON_OUTPUT.resource_group

$AZURE_CONTAINER_REGISTRY_NAME = (az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv)
$AZURE_CONTAINER_REGISTRY_ENDPOINT = (az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv)

$REVISION = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

if((docker buildx ls) -notmatch "wasm-builder"){
    docker buildx create --name wasm-builder --platform wasi/wasm,linux/amd64
}

$IMAGE_NAME = $AZURE_CONTAINER_REGISTRY_ENDPOINT + "/spin-dapr-dotnet:" + $REVISION

docker buildx use wasm-builder
docker buildx build --platform=wasi/wasm --provenance=false --push -t $IMAGE_NAME .
docker buildx use default