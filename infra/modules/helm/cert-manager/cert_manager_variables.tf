variable "namespace" {
  type        = string
  default     = "cert-manager"
  description = "Kubernetes namespace to create and install Cert Manager in"
}
