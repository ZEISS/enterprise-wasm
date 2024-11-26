mod endpoints;
mod errors;

use endpoints::endpoints;
use errors::handle_rejection;
use warp::Filter;

fn app_port() -> u16 {
    match std::env::var("APP_PORT") {
        Ok(port) => match port.parse() {
            Ok(port) => port,
            Err(_) => 8080,
        },
        Err(_) => 8080,
    }
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let subscriber = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(tracing::Level::INFO)
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    let health = warp::get()
        .and(warp::path("healthz"))
        .and(warp::path::end())
        .map(|| "Healthy");

    let routes = health.or(endpoints()).recover(handle_rejection);

    warp::serve(routes).run(([0, 0, 0, 0], app_port())).await;
}
