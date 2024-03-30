# WasmEdge with Dapr in Rust

Hosting: WasmEdge orchestrated by Knative Serving.

kubectl -n kourier-system port-forward svc/kourier-internal 8080:80
curl -v -H "Host: wasmwasi-dapr-rs.default.svc.cluster.local" -d 'Hello' http://localhost:8080/echo
