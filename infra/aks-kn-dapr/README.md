# Resources for Knative and Dapr samples

## deploy

> review and install Azure, Terraform and Helm prerequisites

1. be sure to clear previous state with `rm .terraform.lock.hcl` and `rm -rf .terraform`
1. initialize with `terraform init`
1. create and adjust `terraform.tfvars` to define desired resource naming and location/region or generate with `terraform-docs tfvars hcl . >./terraform.tfvars`

```terraform
resource_prefix           = "my"
location                  = "westus"
tags = {
  "Workload" : "Spin with Dapr on AKS"
}

cluster_admins           = ["00000000-0000-0000-0000-000000000000"]

dapr_deploy  = true
```

<!-- markdownlint-disable-next-line MD029 -->

3. review deployment plan with `terraform plan`
1. deploy with `terraform apply`
1. finalize cluster with `./prepare-cluster.sh`

## configuration values

| name            | (type) purpose                                                                        |
| --------------- | ------------------------------------------------------------------------------------- |
| resource_prefix | gives resouces a unique identifier                                                    |
| location        | Azure region short name                                                               |
| tags            | optional, map(string) to add Azure resource tags if required                          |
| cluster_admins  | optional, list(string) to add AKS RBAC admins                                         |
| monitoring      | string to specify how monitoring is deployed - with `container-insights` or `grafana` |
| dapr_deploy     | bool to specify whether Dapr is deployed with Terraform                               |
