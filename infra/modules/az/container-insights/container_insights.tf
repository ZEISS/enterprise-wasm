###
# Container Insights
###
locals {
  ci_streams = [
    "Microsoft-ContainerLog",
    "Microsoft-ContainerLogV2",
    "Microsoft-KubeEvents",
    "Microsoft-KubePodInventory",
    "Microsoft-KubeNodeInventory",
    "Microsoft-KubePVInventory",
    "Microsoft-KubeServices",
    "Microsoft-KubeMonAgentEvents",
    "Microsoft-InsightsMetrics",
    "Microsoft-ContainerInventory",
    "Microsoft-ContainerNodeInventory",
    "Microsoft-Perf"
  ]
}

resource "azurerm_monitor_data_collection_rule" "msci" {
  name                = "${var.resource_prefix}-msci"
  description         = "DCR for Azure Monitor Container Insights"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = var.loganalytics_id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = local.ci_streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      streams        = local.ci_streams
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        "dataCollectionSettings" : {
          "interval" : "1m",
          "namespaceFilteringMode" : "Off",
          "namespaces" : [
            "kube-system",
            "gatekeeper-system",
            "azure-arc"
          ]
          "enableContainerLogV2" : true
        }
      })
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "msci" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = var.cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.msci.id
  description             = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}
