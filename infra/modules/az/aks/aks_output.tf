output "CLUSTER_ID" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "CLUSTER_NAME" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "NODE_RESOURCE_GROUP" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "KUBE_ADMIN_CONFIG" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config
}

output "KUBE_ADMIN_CONFIG_RAW" {
  value = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
}
