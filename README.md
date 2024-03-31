# Enterprise WebAssembly

Evaluate various WebAssembly back-end frameworks and tool-chains for enterprise workloads.

The background of this repository is explained in [this post "Taking Spin for a spin on AKS"](https://dev.to/kaiwalter/taking-spin-for-a-spin-on-aks-2lf1).

## Acknowledgements

- Team at Fermyon for all the support in helping with the sample setup of Spin and [SpinKube](https://spinkube.dev)
- all the contributors from LiquidReply, Microsoft and others for the components in the background: [Dapr](https://dapr.io), [runwasi](https://github.com/containerd/runwasi), [Kwasm](https://github.com/kwasm), [cert-manager](https://cert-manager.io/)

## General Assumptions

- basic infrastructure code for cloud resources and clusters that could be implemented in a straight-forward way is provided with Terraform and Helm
- additional setup code which required some "incremental development" is in Bash with plain Yaml files (not to bring in additional layers or requirements like Helm, Kustomize)
- for each Wasm variant like Spin/TypeScript, Spin/Rust, WasmEdge/Rust there should be an equivalent for performance comparison in a conventional container based setup like Express/TypeScript or Warp/Rust
- [Dapr](https://dapr.io)

## Repository Structure

### `infra`

Currently this repository contains 2 stacks:

- `aks-spin-dapr` : Spin with Dapr on AKS, Spin as Wasm runtime
- `aks-kn-dapr` : Knative with Dapr on AKS, WasmEdge as Wasm runtime

During deployment with `make deploy` from these 2 infra folders, a `.env` file is written to repository root to guide subsequent scripts on which stack has been deployed:

```
INFRA_FOLDER=infra/aks-spin-dapr
STACK=aks-spin-dapr
```

or

```
INFRA_FOLDER=infra/aks-kn-dapr
STACK=aks-kn-dapr
```

### `samples`

Folder containing the sample workloads which can be used in this infrastructure combinations:

| sample                                       | infrastructure                                                                                    | workload                                         |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| Express with Dapr on AKS, Node.js/TypeScript | [aks-spin-dapr](./infra/aks-spin-dapr/README.md)<br/>[aks-kn-dapr](./infra/aks-kn-dapr/README.md) | [express-dapr-ts](./samples/express-dapr-ts/)    |
| Spin with Dapr on AKS, Node.js/TypeScript    | [aks-spin-dapr](./infra/aks-spin-dapr/README.md)                                                  | [spin-dapr-ts](./samples/spin-dapr-ts/README.md) |
| Spin with Dapr on AKS, Rust                  | [aks-spin-dapr](./infra/aks-spin-dapr/README.md)                                                  | [spin-dapr-rs](./samples/spin-dapr-rs/README.md) |
| Warp / Wasi with Dapr on AKS, Rust           | [aks-kn-dapr](./infra/aks-kn-dapr/README.md)                                                      | [warpwasi-dapr-rs](./samples/warpwasi-dapr-rs/)  |
| Warp with Dapr on AKS, Rust                  | [aks-spin-dapr](./infra/aks-spin-dapr/README.md)                                                  | [warp-dapr-rs](./samples/warp-dapr-rs/)          |

Each of the infrastructure and workload folders contains a `Makefile` with a `make deploy` and `make destroy` rule.

### `helpers`

Helper application and tools like `orderdata-ts` to generate and schedule the test dataset.

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

---

## Compare Express to Spin-ts

The goal of this evaluation is to compare the performance of the same application once in the Express Framework, on the other side in WebAssembly facilitating Spin. Since one benefit of the WebAssembly Ecosystem is the portability, the `spin-dapr-ts` app will be deployed on an ARM nodepool.

In the Setup, Dapr is used to fetch and place messages in a Service Bus queue. Also its used to store the orders of the messages in a storage account. Because we don't want Dapr to be a bottleneck for the Comparison, the Instances of Dapr will be set to 10 without any scaling.

For the Spin / Express apps we search for the most performant scale setting with the given 10 Dapr instances. Which led to 1 to 7 for the spin application and 1 to 10 for the Node.js one.

The Spin app consistently processes the 10000 messages in 20 seconds, whereas Express is more inconsistent. The processing time for the Express app is between 25 and 32 seconds.

## comparison baseline

| VM SKU   | tech specs                         | relative pricing |
| -------- | ---------------------------------- | ---------------- |
| DS3 v2   | 4 vCPUs, 14 GB RAM, 28 GB temp HDD | 1.00             |
| D2pds v5 | 2 vCPUs, 8 GB RAM, 75 GB temp HDD  | 0.40             |
| D4pds v5 | 4 vCPU, 16 GB RAM, 150 GB temp HDD | 0.80             |

## comparison

### performance buckets posture

```
dependencies
| where timestamp >= todatetime('2024-03-09T15:18:16.687Z')
| where name startswith "bindings/q-order"
| extend case = iff(timestamp>=todatetime('2024-03-09T15:46:26.287Z'),"spin","express")
| summarize count() by case, performanceBucket
| render columnchart
```

## debugging

### checking errors Spin from/to Dapr

```kusto
ContainerLogV2
| where TimeGenerated >= todatetime('2024-03-03T09:44:30.509Z')
| where ContainerName == "daprd"
| where LogMessage.msg startswith "App handler returned an error"
| project TimeGenerated, LogMessage
| order by TimeGenerated asc
```
