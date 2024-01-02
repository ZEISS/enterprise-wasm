# Helper to generate test data

## use with local resource Rust implementation

in one terminal session from folder `/samples/spin-dapr-rs` start

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
```
