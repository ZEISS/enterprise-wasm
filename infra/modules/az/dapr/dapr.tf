resource "helm_release" "dapr" {
  name = "dapr"
  # determine chart url from https://github.com/dapr/helm-charts
  chart            = "https://github.com/dapr/helm-charts/raw/master/dapr-${var.dapr_version}.tgz"
  namespace        = var.dapr_namespace
  create_namespace = true
  timeout          = 1200

  set {
    name  = "global.ha.enabled"
    value = "true"
  }

  set {
    name  = "global.tag"
    value = "${var.dapr_version}-mariner"
  }
}
