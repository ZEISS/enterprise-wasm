output "kube_config" {
  value     = module.aks.KUBE_ADMIN_CONFIG_RAW
  sensitive = true
}

output "script_vars" {
  value = {
    "resource_group" = azurerm_resource_group.rg.name
    "base_name"      = local.base_name
  }
}

