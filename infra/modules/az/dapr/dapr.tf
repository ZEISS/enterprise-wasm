resource "helm_release" "dapr" {
  name = "dapr"
  # determine chart url from https://github.com/dapr/helm-charts
  chart            = "https://github.com/dapr/helm-charts/raw/master/dapr-${var.dapr_version}.tgz"
  namespace        = var.dapr_namespace
  create_namespace = true
  timeout          = 1200

  values = [
    <<-EOF
    global:
      nodeSelector:
        agentpool: ${var.dapr_agentpool}
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      ha:
        enabled: true
      tag: ${var.dapr_version}-mariner
    EOF
  ]
}
