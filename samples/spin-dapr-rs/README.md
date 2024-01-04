# Spin with Dapr in Rust

## build

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
