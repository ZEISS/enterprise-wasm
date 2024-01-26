variable "namespace" {
  type        = string
  default     = "keda-system"
  description = "Kubernetes namespace to create and install KEDA in"
}

variable "keda_agentpool" {
  type        = string
  default     = "default"
  description = "Agent pool name to deploy KEDA to"
}
