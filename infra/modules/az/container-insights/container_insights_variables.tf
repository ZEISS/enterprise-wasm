variable "cluster_id" {
  description = "Resource Id of AKS cluster."
  type        = string
}

variable "loganalytics_id" {
  description = "Resource Id of Log Analytics."
  type        = string
}

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
