# Enterprise WebAssembly

Evaluate various WebAssembly back-end frameworks and tool-chains for enterprise workloads

> STATUS : **UNDER CONSTRUCTION**

## Prequisites

### Azure

To use Azure examples in this repository these tools are required:

- Azure CLI version >= `2.55.0`

Before starting deployments, optionally execute these steps

- `az login` to your Azure account and set the desired subscription with `az account set -s {subscription-id}`
- create a service principal e.g. with `az ad sp create-for-rbac --name "My Terraform Service Principal" --role="Contributor" --scopes="/subscriptions/$(az account show --query id -o tsv)"` to create and assign `Contributor` authorizations on the subscription currently set in Azure CLI
- from the output like

```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "My Terraform Service Principal",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

- note down, create a script or extend your session initialization script like `.bashr` or `.zshrc` to set Terraform environment variables:

```shell
export ARM_SUBSCRIPTION_ID="{subscription-id}"
export ARM_TENANT_ID="{tenant}"
export ARM_CLIENT_ID="{appId}"
export ARM_CLIENT_SECRET="{password}"
```

- or when running these samples with **GitHub Codespaces**, add 4 secrets `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET` and assign those to this repository or the fork of the repository you are using
- assign RBAC management authorization to service principal with `az role assignment create --role 'Role Based Access Control Administrator' --scope /subscriptions/$ARM_SUBSCRIPTION_ID --assignee $ARM_CLIENT_ID` so that various role assignments can be conducted by Terraform
- if you want to sign in with the above credentils to your current Azure CLI session, use `az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID && az account set -s $ARM_SUBSCRIPTION_ID`

### Terraform & Helm

All infrastructure in this repository is defined with [Terraform templates](https://www.terraform.io/) with linked [Helm charts](https://helm.sh/) which requires these tools:

- Terraform CLI version >= `1.6.6`
- Helm CLI version >= `3.13.1`
- jq version >= `1.6`
- yq version >= `4.40.4`

optional:

- [terraform-docs](https://terraform-docs.io/user-guide/installation/) >= `0.16.0`

## Sample Workloads

| sample                | infrastructure                    | workload                           |
| --------------------- | --------------------------------- | ---------------------------------- |
| Spin with Dapr on AKS | <./infra/aks-spin-dapr/README.md> | <./samples/spin-dapr-ts/README.md> |
