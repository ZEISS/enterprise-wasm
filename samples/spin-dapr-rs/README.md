# Spin with Dapr in Rust

## build

```
spin build
```

## verify

### run single instance covering all workloads

in 1st terminal session

```
./run.sh
```

in 2nd terminal session

```
./test-binding.sh
```

### run separate instances with Dapr multi run

in 1st terminal session

```
dapr run -f dapr-multi-run.yml
```

in 2nd terminal session

```
./test-binding.sh
```
