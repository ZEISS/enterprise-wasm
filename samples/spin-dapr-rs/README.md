# Spin with Dapr in Rust

The current version assumes, that following GitHub repositories are cloned locally to folders with the same parent folder as this repository:

| repository                                    | branch | folder      |
| --------------------------------------------- | ------ | ----------- |
| <https://github.com/dapr-sandbox/dapr-shared> | main   | dapr-shared |

## build (locally)

```
spin build
```

## verify

### run with local resources and Dapr multi run

> based on **Azurite** local Azure storage and queue emulator

in 1st terminal session

```
./run-local-resources.sh
```

in 2nd terminal session

```
./test-local-binding.sh
```

### run single instance covering all workloads with Azure resources

in 1st terminal session

```
./run.sh
```

in 2nd terminal session

```
./test-local-binding.sh
```

### build & run on AKS with Azure resources

> deploy infrastructure [from here](../../infra/aks-spin-dapr/README.md)

```
./build.sh
./deploy.sh
./test-spin-dapr-aks.sh
```

### queries in Application Insights

#### evaluate one run

```
dependencies
| where timestamp >= todatetime('2024-01-10T19:11:23.709Z')
| where name startswith "bindings/q-order"
| summarize count() by bin(timestamp,15s), cloud_RoleName
| render columnchart
```

#### compare 2 runs

```
let sidecar=dependencies
| where timestamp between ( todatetime('2024-01-14T09:07:57.872Z') .. todatetime('2024-01-14T09:40:50+00:00') )
| where name startswith "bindings/q"
| summarize count() by performanceBucket, name
| project performanceBucket, name, sidecar=count_
;
let shared=dependencies
| where timestamp >= todatetime('2024-01-14T09:47:13.035Z')
| where name startswith "bindings/q"
| summarize count() by performanceBucket, name
| project performanceBucket, name, shared=count_
;
sidecar | union shared
| summarize sum(sidecar), sum(shared) by name, performanceBucket
| order by name, performanceBucket
```
