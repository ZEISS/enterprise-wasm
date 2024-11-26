```
rustup target add wasm32-wasip1
cargo build --target wasm32-wasip1 --release
chmod +x ./target/wasm32-wasip1/release/http_server.wasm
wasmedge ./target/wasm32-wasip1/release/http_server.wasm
```
