# WasmEdge with Dapr in Rust

Hosting: WasmEdge orchestrated by Knative Serving.

## Learning

- adding [HTTPS Support](https://wasmedge.org/docs/develop/rust/http_service/client#https-support) causes `wasmedge run` to break with some linking error

## Links

- <https://wasmedge.org/book/en/use_cases/frameworks/mesh/dapr.html>
- <https://wasmedge.org/docs/develop/rust/http_service/server#the-warp-api>
- <https://wasmedge.org/docs/develop/rust/http_service/client#the-reqwest-api>
- <https://github.com/WasmEdge/wasmedge_hyper_demo/tree/main/server-warp>
- <https://wasmedge.org/book/en/use_cases/frameworks/mesh/dapr>

## Misc

### calling Knative Serving hosted Wasm module

simple deploy with

```
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: wasmwasi-dapr-rs
  namespace: default
spec:
  template:
    metadata:
      annotations:
        module.wasm.image/variant: compat-smart
    spec:
      runtimeClassName: wasmedge-v1
      timeoutSeconds: 1
      containers:
        - name: http-server
          image: xxxxxx.azurecr.io/warpwasi-dapr-rs:1711727994
          ports:
            - containerPort: 8080
              protocol: TCP
          livenessProbe:
            tcpSocket:
              port: 8080
```

then test with

```
kubectl -n kourier-system port-forward svc/kourier-internal 8080:80
curl -v -H "Host: wasmwasi-dapr-rs.default.svc.cluster.local" -d 'Hello' http://localhost:8080/echo
```
