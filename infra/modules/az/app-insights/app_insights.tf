resource "azurerm_application_insights" "appins" {
  name                = "${var.resource_prefix}-appins"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  workspace_id        =var.loganalytics_id 
  application_type    = "web"
}
