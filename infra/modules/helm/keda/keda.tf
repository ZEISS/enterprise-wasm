resource "kubernetes_namespace" "keda" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
    namespace = kubernetes_namespace.keda.metadata.0.name

  values = [
    <<-EOF
    nodeSelector:
      agentpool: ${var.keda_agentpool}
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
    EOF
  ]
}

# resource "helm_release" "keda_http" {
#   name       = "keda-http-add-on"
#   repository = "https://kedacore.github.io/charts"
#   chart      = "keda-add-ons-http"
#     namespace = kubernetes_namespace.keda.metadata.0.name
#
#   values = [
#     <<-EOF
#     operator:
#       nodeSelector:
#         agentpool: ${var.keda_agentpool}
#       tolerations:
#         - key: "CriticalAddonsOnly"
#           operator: "Exists"
#     scaler:
#       nodeSelector:
#         agentpool: ${var.keda_agentpool}
#       tolerations:
#         - key: "CriticalAddonsOnly"
#           operator: "Exists"
#     interceptor:
#       nodeSelector:
#         agentpool: ${var.keda_agentpool}
#       tolerations:
#         - key: "CriticalAddonsOnly"
#           operator: "Exists"
#     EOF
#   ]
# }
