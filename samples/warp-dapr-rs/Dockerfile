FROM rust:bookworm as builder

WORKDIR /app

COPY Cargo.toml .
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release

COPY src src
RUN touch src/main.rs
RUN cargo build --release

# RUN strip target/release/warp-dapr-rs

# --- 
FROM debian:bookworm-slim

RUN apt-get update && apt install -y openssl

COPY --from=builder /app/target/release/warp-dapr-rs /

ENTRYPOINT ["./warp-dapr-rs"]
