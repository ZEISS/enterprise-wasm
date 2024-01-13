resource "kubernetes_namespace" "kwasm" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_daemonset" "kwasm_installer" {
  metadata {
    name      = "kwasm-installer"
    namespace = kubernetes_namespace.kwasm.metadata.0.name
    labels = {
      app = "kwasm-installer"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "kwasm-installer"
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app = "kwasm-installer"
        }
      }

      spec {
        # must have access to host pid to restart containerd
        host_pid = true

        volume {
          name = "node-root"
          host_path {
            path = "/"
          }
        }

        init_container {
          name  = "kwasm-initializer"
          image = var.installer_image

          # must be privileged to restart containerd
          security_context {
            privileged = true
          }

          volume_mount {
            name       = "node-root"
            mount_path = "/mnt/node-root"
          }

          env {
            name  = "NODE_ROOT"
            value = "/mnt/node-root"
          }
        }

        container {
          name  = "pause"
          image = var.pause_image
        }

        node_selector = var.node_selector

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/os"
                  operator = "In"
                  values   = ["linux"]
                }

                match_expressions {
                  key      = "type"
                  operator = "NotIn"
                  values   = ["virtual-kubelet"]
                }

                # prefer user nodes
                match_expressions {
                  key      = "kubernetes.azure.com/mode"
                  operator = "NotIn"
                  values   = ["system"]
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_runtime_class_v1" "spin_v2" {
  metadata {
    name = var.runtime_class_name
  }

  handler = "spin"
}
# This resource requires API access during planning time
# resource "kubernetes_manifest" "spin_v2" {
#   manifest = {
#     apiVersion = "node.k8s.io/v1"
#     kind       = "RuntimeClass"
#     metadata = {
#       name = var.runtime_class_name
#     }
#     handler = "spin"
#     scheduling = {
#       nodeSelector = var.node_selector
#     }
#   }
# }
