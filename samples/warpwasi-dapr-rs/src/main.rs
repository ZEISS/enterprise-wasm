mod dapr_endpoints;
mod errors;
mod models;

use dapr_endpoints::dapr_endpoints;
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
    let health = warp::get()
        .and(warp::path("healthz"))
        .and(warp::path::end())
        .map(|| "Healthy");

    let routes = health.or(dapr_endpoints()).recover(handle_rejection);

    warp::serve(routes).run(([0, 0, 0, 0], app_port())).await
}
