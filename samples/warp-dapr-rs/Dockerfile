FROM rust as builder

WORKDIR /app

COPY Cargo.toml .
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release

COPY src src
RUN touch src/main.rs
RUN cargo build --release

RUN strip target/release/warp-dapr-rs

# --- 
FROM rust as runtime

WORKDIR /app

COPY --from=builder /app/target/release/warp-dapr-rs /usr/local/bin

ENTRYPOINT ["/usr/local/bin/warp-dapr-rs"]
