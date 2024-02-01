// source: https://blog.logrocket.com/building-rest-api-rust-warp/

use std::u16;

use reqwest::StatusCode;
use warp::Filter;

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct OrderItem {
    order_item_id: u32,
    sku: String,
    quantity: u32,
}

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
#[allow(dead_code)]
struct Order {
    order_id: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    order_guid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    first_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    last_name: Option<String>,
    delivery: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    items: Option<Vec<OrderItem>>,
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct OutboundMessage<'a> {
    data: &'a Order,
    operation: String,
}

impl<'a> OutboundMessage<'a> {
    pub fn new(data: &'a Order) -> Self {
        Self {
            data,
            operation: "create".to_owned(),
        }
    }
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct OutboxMetadata {
    blob_name: String,
}

#[derive(serde::Serialize)]
struct OutboxCreate<'a> {
    data: &'a Order,
    operation: String,
    metadata: OutboxMetadata,
}

impl<'a> OutboxCreate<'a> {
    pub fn new(order: &'a Order) -> Self {
        Self {
            data: order,
            operation: "create".to_owned(),
            metadata: OutboxMetadata {
                blob_name: order.order_id.to_string(),
            },
        }
    }
}

async fn health() -> Result<impl warp::Reply, warp::Rejection> {
    Ok(warp::reply::with_status("Healthy", StatusCode::OK))
}

#[derive(Debug)]
struct RequestError;
impl warp::reject::Reject for RequestError {}

fn dapr_url() -> String {
    match std::env::var("DAPR_URL") {
        Ok(url) => url,
        Err(_) => "http://localhost:3500".to_string(),
    }
}

fn app_port() -> u16 {
    match std::env::var("APP_PORT") {
        Ok(port) => match port.parse() {
            Ok(port) => port,
            Err(_) => 8080,
        },
        Err(_) => 8080,
    }
}

async fn dapr_metadata() -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let mut url = url::Url::parse(&dapr_url).expect("Dapr URL");
    url.set_path("v1.0/metadata");

    match reqwest::get(url).await.expect("get").text().await {
        Ok(response) => Ok(warp::reply::with_status(response, StatusCode::OK)),
        Err(_) => Err(warp::reject::custom(RequestError)),
    }
}

async fn distributor(order: Order) -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let path = format!(
        "v1.0/bindings/q-order-{}-out",
        &order.delivery.to_lowercase()
    );
    let mut url = url::Url::parse(&dapr_url).expect("Dapr URL");
    url.set_path(&path);

    let outbound_message = OutboundMessage::new(&order);
    let body = serde_json::to_string(&outbound_message).expect("serialize outbound message");
    println!("Distributor body {}", body);

    match reqwest::Client::new()
        .post(url)
        .json(&outbound_message)
        .send()
        .await
    {
        Ok(response) => Ok(warp::reply::with_status(
            response.text().await.expect("response"),
            StatusCode::OK,
        )),
        Err(_) => Err(warp::reject::custom(RequestError)),
    }
}

async fn receiver(order: Order) -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let path = format!("v1.0/bindings/{}-outbox", &order.delivery.to_lowercase());
    let mut url = url::Url::parse(&dapr_url).expect("Dapr URL");
    url.set_path(&path);

    let outbox_create = OutboxCreate::new(&order);
    let body = serde_json::to_string(&outbox_create).expect("serialize outbound message");
    println!("Receiver body {}", body);

    match reqwest::Client::new()
        .post(url)
        .json(&outbox_create)
        .send()
        .await
    {
        Ok(response) => Ok(warp::reply::with_status(
            response.text().await.expect("response"),
            StatusCode::OK,
        )),
        Err(_) => Err(warp::reject::custom(RequestError)),
    }
}

fn json_body() -> impl Filter<Extract = (Order,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(1024 * 16).and(warp::body::json())
}

#[tokio::main]
async fn main() {
    let subscriber = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(tracing::Level::INFO)
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    let get_health = warp::get()
        .and(warp::path("healthz"))
        .and(warp::path::end())
        .and_then(health);

    let get_dapr_metadata = warp::get()
        .and(warp::path("dapr-metadata"))
        .and(warp::path::end())
        .and_then(dapr_metadata);

    let post_distributor = warp::post()
        .and(warp::path("q-order-ingress"))
        .and(warp::path::end())
        .and(json_body())
        .and_then(distributor);

    let post_receiver_express = warp::post()
        .and(warp::path("q-order-express-in"))
        .and(warp::path::end())
        .and(json_body())
        .and_then(receiver);

    let post_receiver_standard = warp::post()
        .and(warp::path("q-order-standard-in"))
        .and(warp::path::end())
        .and(json_body())
        .and_then(receiver);

    let routes = get_health
        .or(get_dapr_metadata)
        .or(post_distributor)
        .or(post_receiver_express)
        .or(post_receiver_standard);

    warp::serve(routes).run(([0, 0, 0, 0], app_port())).await;
}
