variable "namespace" {
  type        = string
  default     = "kwasm-system"
  description = "Kubernetes namespace to create and install KWasm in"
}

variable "installer_image" {
  type        = string
  default     = "ghcr.io/kwasm/kwasm-node-installer:v0.3.1"
  description = "KWasm installer image to use"
}

variable "node_selector" {
  type        = map(string)
  default     = {}
  description = "Node selector to use for daemonset"
}

variable "runtime_class_name" {
  type        = string
  default     = "wasmtime-spin-v2"
  description = "Runtime class name to use for Spin wasm containers"
}

variable "pause_image" {
  type        = string
  default     = "k8s.gcr.io/pause:3.1"
  description = "Pause image to use for daemonset"
}
