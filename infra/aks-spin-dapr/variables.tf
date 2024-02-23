variable "location" {
  type        = string
  default     = "eastus"
  description = "Desired Azure Region"
}

variable "resource_prefix" {
  type        = string
  default     = "asd"
  description = "Desired Resource Prefix to be used for all resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    project = "Spin with Dapr on AKS"
  }
}

variable "monitoring" {
  type        = string
  description = "Sets cluster monitoring environment to use: container-insights, grafana"
  default     = "container-insights"

  validation {
    condition     = contains(["container-insights", "grafana"], var.monitoring)
    error_message = "Valid values for var: monitoring are (container-insights, grafana)."
  }
}

variable "cluster_admins" {
  type        = list(string)
  default     = []
  description = "List of cluster administrators"
}

variable "cluster_version" {
  type        = string
  default     = "1.27.7"
  description = "Kubernetes version to install."
}

variable "system_nodepool" {
  type = object({
    name = string
    size = string
    min  = number
    max  = number
  })
  default = {
    name = "system"
    size = "Standard_DS2_v2"
    min  = 2
    max  = 3
  }
}

variable "user_nodepools" {
  type = list(object({
    name       = string
    size       = string
    node_count = number
    max_pods   = number
    labels     = map(string)
    taints     = list(string)
  }))
  default = [{
    name       = "default"
    size       = "Standard_DS2_v2"
    node_count = 3
    max_pods   = 250
    labels = {
    }
    taints = []
    }, {
    name       = "wasm"
    size       = "Standard_D2pds_v5"
    node_count = 3
    max_pods   = 250
    labels = {
    }
    taints = []
    }, {
    name       = "classic"
    size       = "Standard_DS2_v2"
    node_count = 3
    max_pods   = 250
    labels = {
    }
    taints = []
  }]
}

variable "queues" {
  type = list(object({
    name = string
  }))
  default = [{
    name = "q-order-ingress-spin"
    }, {
    name = "q-order-express-spin"
    }, {
    name = "q-order-standard-spin"
  }]
}

variable "topics" {
  type = list(object({
    name = string
  }))
  default = []
}

variable "dapr_deploy" {
  type        = bool
  default     = true
  description = "Indicate whether to deploy Dapr directly with cluster"
}

variable "dapr_version" {
  type        = string
  default     = "1.12.3"
  description = "Dapr version to install with Helm charts"
}

variable "dapr_namespace" {
  type        = string
  default     = "dapr-system"
  description = "Kubernetes namespace to install Dapr in"
}

variable "dapr_agentpool" {
  type        = string
  default     = null
  description = "Agent pool name to deploy Dapr to. Uses the default nodepool if null"
}

variable "kwasm_deploy" {
  type        = bool
  default     = true
  description = "Indicate whether to deploy KWasm directly with cluster"
}

variable "kwasm_namespace" {
  type        = string
  default     = "kwasm-system"
  description = "Kubernetes namespace to install KWasm in"
}

variable "kwasm_installer_image" {
  type        = string
  default     = "ghcr.io/kwasm/kwasm-node-installer:v0.3.1"
  description = "KWasm installer image to use"
}

variable "kwasm_node_selector" {
  type        = map(string)
  default     = { agentpool = "wasm" }
  description = "Node selector to use for KWasm daemonset"
}

variable "kwasm_runtime_class_name" {
  type        = string
  default     = "wasmtime-spin-v2"
  description = "Runtime class name to use for Spin wasm containers"
}

variable "keda_deploy" {
  type        = bool
  default     = true
  description = "Indicate whether to deploy KEDA directly with cluster"
}

variable "keda_namespace" {
  type        = string
  default     = "keda-system"
  description = "Kubernetes namespace to install KEDA in"
}

variable "spin_deploy" {
  type        = string
  description = "Defines how Spin is deployed into the cluster"
  default     = "operator"

  validation {
    condition     = contains(["operator", "deploy"], var.spin_deploy)
    error_message = "Valid values for var: spin_deploy are (operator, deploy)."
  }
}
