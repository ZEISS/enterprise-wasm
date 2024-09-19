# Helper to generate test data

## setup spin otel collector (for local development)
Ensure using the latest version of spin.

Run:
```
spin plugins update
spin plugins install otel
```

Start the Spin Otel resources: (docker required)
```
spin otel setup
```

use the dashboard of your choice:
```
spin otel open grafana
spin otel open jaeger
spin otel open prometheus
```

important: stop the resources if you don't need them anymore:
```
spin otel cleanup
```


## local test local resources

```
./run-local-resources.sh
```

in another terminal session:

create test data in Blob

```
curl -d '{"count":100}' http://localhost:3000/test-data  -H 'Content-Type: application/json'
```

query test data from Blob

```
curl http://localhost:3000/test-data
```

schedule a test

```
curl -d '{}' http://localhost:3000/schedule-test
```

## use with local resources / Rust implementation

in one terminal session from folder [/samples/spin-dapr-rs](../../samples/spin-dapr-rs/) start

```
./run-local-resources.sh
```

in a second terminal session from this repository run

```
npm start
```

then in a final session generate test data to flow into the Rust sample

```
curl -v -d '{"count":10}' http://localhost:3000/test-data -H 'Content-Type: application/json'
curl -v -d '{}' http://localhost:3000/schedule-test -H 'Content-Type: application/json'
```

## use with cloud resources / Rust implementation

> deploy all required Azure resources from [Rust sample](../../samples/spin-dapr-rs/README.md)

```
./run-cluster.sh
```
