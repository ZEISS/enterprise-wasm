data "azurerm_client_config" "current" {}

resource "random_pet" "dns_infix" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.resource_prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  dns_prefix          = "${var.resource_prefix}-${random_pet.dns_infix.id}"

  kubernetes_version = var.cluster_version
  sku_tier           = "Free"

  default_node_pool {
    name                         = var.system_nodepool.name
    node_count                   = var.system_nodepool.min
    vm_size                      = var.system_nodepool.size
    enable_auto_scaling          = var.system_nodepool.min != var.system_nodepool.max
    min_count                    = var.system_nodepool.min != var.system_nodepool.max ? var.system_nodepool.min : null
    max_count                    = var.system_nodepool.min != var.system_nodepool.max ? var.system_nodepool.max : null
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    managed            = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id      = var.loganalytics_id
    msi_auth_for_monitoring_enabled = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_nodepools" {
  count = length(var.user_nodepools)

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = var.user_nodepools[count.index].name
  vm_size               = var.user_nodepools[count.index].size
  tags                  = var.tags

  mode    = "User"
  os_type = "Linux"
  os_sku  = "Ubuntu"

  node_count = var.user_nodepools[count.index].node_count

  node_labels = var.user_nodepools[count.index].labels
  node_taints = var.user_nodepools[count.index].taints

  max_pods = var.user_nodepools[count.index].max_pods
}

# assign role for AKS cluster admins

resource "azurerm_role_assignment" "aks_admin_role_assignment" {
  for_each             = toset(var.cluster_admins)
  principal_id         = each.value
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
}

# assign role required for Container Registry pull

resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  scope                = var.acr_id
  role_definition_name = "AcrPull"
}
