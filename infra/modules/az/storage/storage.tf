resource "azurerm_storage_account" "st" {
  name                = format("%s%s", replace(var.resource_prefix, "-", ""), "st")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
}
