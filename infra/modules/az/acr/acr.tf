resource "azurerm_container_registry" "acr" {
  name                = format("%s%s", replace(var.resource_prefix, "-", ""), "acr")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku = "Premium"

  admin_enabled                 = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  network_rule_bypass_option    = "AzureServices"
}

resource "azurerm_user_assigned_identity" "acr_pull_identity" {
  name                = "${var.resource_prefix}-acrpull"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull_assignment" {
  principal_id         = azurerm_user_assigned_identity.acr_pull_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
