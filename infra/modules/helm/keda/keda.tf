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

  devel = "true"

  set {
    name  = "logLevel"
    value = "debug"
  }
}
