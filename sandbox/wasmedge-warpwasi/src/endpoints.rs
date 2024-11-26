use crate::errors::ServiceError;
use reqwest::StatusCode;
use warp::Filter;

pub fn endpoints() -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    let get_external = warp::get()
        .and(warp::path("external"))
        .and(warp::path::end())
        .and_then(get_external);

    get_external
}

async fn get_external() -> Result<impl warp::Reply, warp::Rejection> {
    let url =
        url::Url::parse("http://eu.httpbin.org/ip").map_err(|e| ServiceError::ParseError(e))?;
    tracing::info!("test url {}", url);

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
