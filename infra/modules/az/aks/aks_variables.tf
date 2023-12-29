variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "resource_prefix" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
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
}

variable "loganalytics_id" {
  description = "Resource Id of Log Analytics."
  type        = string
}

variable "loganalytics_name" {
  description = "Resource name of Log Analytics."
  type        = string
}

variable "acr_id" {
  description = "Resource Id of Container Registry."
  type        = string
}
