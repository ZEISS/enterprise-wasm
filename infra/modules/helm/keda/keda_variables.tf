variable "namespace" {
  type        = string
  default     = "keda-system"
  description = "Kubernetes namespace to create and install KEDA in"
}
