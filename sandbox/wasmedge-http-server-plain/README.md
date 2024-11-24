```
cargo build --target wasm32-wasi --release
chmod +x ./target/wasm32-wasi/release/http_server.wasm
wasmedge ./target/wasm32-wasi/release/http_server.wasm
```
