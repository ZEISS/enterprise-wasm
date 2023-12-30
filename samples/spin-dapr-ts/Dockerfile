FROM scratch
COPY ./target/spin-dapr-ts.wasm ./target/spin-dapr-ts.wasm
COPY ./spin.toml /spin.toml
ENTRYPOINT ["/spin.toml"]
