FROM scratch
COPY ./target/wasm32-wasi/release/spin_dapr_rs.wasm ./target/wasm32-wasi/release/spin_dapr_rs.wasm
COPY ./spin.toml /spin.toml
ENTRYPOINT ["/spin.toml"]
