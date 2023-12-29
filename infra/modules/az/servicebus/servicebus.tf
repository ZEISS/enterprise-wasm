resource "azurerm_servicebus_namespace" "sb" {
  name                = format("%s%s", replace(var.resource_prefix, "-", ""), "sb")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku = "Standard"
}

resource "azurerm_servicebus_topic" "load" {
  name         = "load"
  namespace_id = azurerm_servicebus_namespace.sb.id

  enable_partitioning = true
}

resource "azurerm_servicebus_topic_authorization_rule" "sb_load" {
  name     = "send_listen"
  topic_id = azurerm_servicebus_topic.load.id

  listen = true
  send   = true
  manage = true
}
