output "CONTAINER_REGISTRY_ID" {
  value = azurerm_container_registry.acr.id
}

output "CONTAINER_REGISTRY_NAME" {
  value = azurerm_container_registry.acr.name
}

output "CONTAINER_REGISTRY_ENDPOINT" {
  value = azurerm_container_registry.acr.login_server
}

output "CONTAINER_REGISTRY_PULL_IDENTITY_ID" {
  value = azurerm_user_assigned_identity.acr_pull_identity.id
}
