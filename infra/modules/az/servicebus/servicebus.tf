resource "azurerm_servicebus_namespace" "sb" {
  name                = format("%s%s", replace(var.resource_prefix, "-", ""), "sb")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku      = var.sku
  capacity = var.capacity
}

resource "azurerm_servicebus_namespace_authorization_rule" "workload_rule" {
  name         = "workloads"
  namespace_id = azurerm_servicebus_namespace.sb.id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_servicebus_topic" "workload_topics" {
  count = length(var.topics)

  name         = var.topics[count.index].name
  namespace_id = azurerm_servicebus_namespace.sb.id

  enable_partitioning = true
}

resource "azurerm_servicebus_queue" "workload_queues" {
  count = length(var.queues)

  name         = var.queues[count.index].name
  namespace_id = azurerm_servicebus_namespace.sb.id

  enable_partitioning = true
}