FROM docker.io/library/rust:latest AS builder

RUN rustup target add wasm32-wasi

WORKDIR /build

COPY Cargo.lock .
COPY Cargo.toml .
RUN mkdir src && touch src/main.rs && cargo fetch

COPY . .
RUN cargo build --target wasm32-wasi --release

FROM scratch

COPY --from=builder /etc/services /etc/services
COPY --from=builder /build/target/wasm32-wasi/release/warpwasi_dapr_rs.wasm warpwasi_dapr_rs.wasm 

EXPOSE 8080

ENTRYPOINT [ "warpwasi_dapr_rs.wasm" ]
