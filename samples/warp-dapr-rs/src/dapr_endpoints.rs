use crate::errors::ServiceError;
use crate::models::*;
use reqwest::StatusCode;
use warp::Filter;

fn json_body() -> impl Filter<Extract = (Order,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(1024 * 16).and(warp::body::json())
}

fn dapr_url() -> String {
    match std::env::var("DAPR_URL") {
        Ok(url) => url,
        Err(_) => "http://localhost:3500".to_string(),
    }
}

pub fn dapr_endpoints() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone
{
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

    get_dapr_metadata
        .or(post_distributor)
        .or(post_receiver_express)
        .or(post_receiver_standard)
}

async fn dapr_metadata() -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let mut url = url::Url::parse(&dapr_url).map_err(|e| ServiceError::ParseError(e))?;
    url.set_path("v1.0/metadata");

    let response = reqwest::Client::new()
        .get(url)
        .send()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?
        .text()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?;

    Ok(warp::reply::with_status(response, StatusCode::OK))
}

async fn distributor(order: Order) -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let path = format!(
        "v1.0/bindings/q-order-{}-out",
        &order.delivery.to_lowercase()
    );
    let mut url = url::Url::parse(&dapr_url).map_err(|e| ServiceError::ParseError(e))?;
    url.set_path(&path);

    let outbound_message = OutboundMessage::new(&order);
    let body = serde_json::to_string(&outbound_message).expect("serialize outbound message");
    tracing::info!("Distributor request {}", body);

    let response = reqwest::Client::new()
        .post(url)
        .json(&outbound_message)
        .send()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?
        .text()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?;
    tracing::info!("Distributor response {}", response);

    Ok(warp::reply::with_status(response, StatusCode::OK))
}

async fn receiver(order: Order) -> Result<impl warp::Reply, warp::Rejection> {
    let dapr_url = dapr_url();
    let path = format!("v1.0/bindings/{}-outbox", &order.delivery.to_lowercase());
    let mut url = url::Url::parse(&dapr_url).map_err(|e| ServiceError::ParseError(e))?;
    url.set_path(&path);

    let outbox_create = OutboxCreate::new(&order);
    let body = serde_json::to_string(&outbox_create).expect("serialize outbound message");
    tracing::info!("Receiver body {}", body);

    let response = reqwest::Client::new()
        .post(url)
        .json(&outbox_create)
        .send()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?
        .text()
        .await
        .map_err(|e| ServiceError::ReqwestError(e))?;

    Ok(warp::reply::with_status(response, StatusCode::OK))
}
