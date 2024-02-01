// source: https://blog.logrocket.com/building-rest-api-rust-warp/

use parking_lot::RwLock;
use reqwest::{Error, StatusCode};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use warp::reply::json;
use warp::{http, Filter, Rejection, Reply};

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
struct FetchError;
impl warp::reject::Reject for FetchError {}

async fn fetch_url(url: reqwest::Url) -> Result<String, reqwest::Error> {
    reqwest::get(url).await?.text().await
}

async fn dapr_metadata() -> Result<impl warp::Reply, warp::Rejection> {
    let url = url::Url::parse("http://localhost:3500/v1.0/metadata").expect("Dapr URL");
    match fetch_url(url).await {
        Ok(response) => Ok(warp::reply::with_status(response, StatusCode::OK)),
        Err(_) => Err(warp::reject::custom(FetchError)),
    }
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

    let routes = get_health.or(get_dapr_metadata);

    warp::serve(routes).run(([0, 0, 0, 0], 8080)).await;
}
