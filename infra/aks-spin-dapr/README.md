# Resources for Spin and Dapr samples

## deploy

> review and install Azure, Terraform and Helm prerequisites

1. be sure to clear previous state with `rm .terraform.lock.hcl` and `rm -rf .terraform`
1. initialize with `terraform init`
1. create and adjust `terraform.tfvars` to define desired resource naming and location/region or generate with `terraform-docs tfvars hcl . >./terraform.tfvars`

```terraform
resource_prefix           = "my"
location                  = "westus"
dapr_deploy               = true
tags = {
  "Workload" : "Spin with Dapr on AKS"
}
purge_protection_enabled = false
secretstore_admins       = ["00000000-0000-0000-0000-000000000000"]
cluster_admins           = ["00000000-0000-0000-0000-000000000000"]
```

<!-- markdownlint-disable-next-line MD029 -->

3. review deployment plan with `terraform plan`
1. deploy with `terraform apply`
1. finalize cluster with `./prepare-cluster.sh`

## verify

### Spin ContainerD Shim installation

```
kubectl -n kube-system logs daemonset/spin-containerd-shim-installer -c installer --timestamps=true --prefix=true -f
```

desired output (with my <https://github.com/kaiwalter/spin-containerd-shim-installer>, branch debug)

```
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885344712Z errexit         on
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885368212Z noglob          off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885371912Z ignoreeof       off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885375012Z monitor         off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885378012Z noexec          off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885381012Z xtrace          off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885384112Z verbose         off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885387112Z noclobber       off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885390112Z allexport       off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885393012Z notify          off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885395812Z nounset         on
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885398912Z errtrace        off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885401812Z vi              off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885404612Z pipefail        off
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.885407612Z copying the shim to the node's bin directory '/host/bin'
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.915427352Z './containerd-shim-spin-v2' -> '/host/bin/containerd-shim-spin-v2'
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916755654Z /host/bin/containerd-shim-slight-v0-3-0-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916763954Z /host/bin/containerd-shim-slight-v0-5-1-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916767154Z /host/bin/containerd-shim-slight-v0-8-0-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916770254Z /host/bin/containerd-shim-spin-v0-3-0-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916773354Z /host/bin/containerd-shim-spin-v0-5-1-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916776354Z /host/bin/containerd-shim-spin-v0-8-0-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916779354Z /host/bin/containerd-shim-spin-v2
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.916782254Z /host/bin/containerd-shim-wws-v0-8-0-v1
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.918103056Z adding spin runtime 'io.containerd.spin.v2' to /host/etc/containerd/config.toml
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.922513262Z committed changes to containerd config
[pod/spin-containerd-shim-installer-fq5z9/installer] 2023-12-30T10:29:36.922524062Z restarting containerd
```
