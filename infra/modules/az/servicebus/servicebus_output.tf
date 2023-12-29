output "LOAD_CONNECTION_STRING" {
  value = azurerm_servicebus_topic_authorization_rule.sb_load.primary_connection_string
}
