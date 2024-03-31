#[derive(Debug)]
pub enum ServiceError {
    ParseError(url::ParseError),
    ReqwestError(reqwest::Error),
}
impl warp::reject::Reject for ServiceError {}

pub async fn handle_rejection(
    err: warp::Rejection,
) -> Result<impl warp::Reply, std::convert::Infallible> {
    let response = if err.is_not_found() {
        http_api_problem::HttpApiProblem::with_title(http_api_problem::StatusCode::NOT_FOUND)
    } else if let Some(e) = err.find::<ServiceError>() {
        match e {
            ServiceError::ParseError(e) => http_api_problem::HttpApiProblem::with_title(
                http_api_problem::StatusCode::INTERNAL_SERVER_ERROR,
            )
            .detail(format!("{}", e)),
            ServiceError::ReqwestError(e) => http_api_problem::HttpApiProblem::with_title(
                http_api_problem::StatusCode::SERVICE_UNAVAILABLE,
            )
            .detail(format!("{}", e)),
        }
    } else {
        http_api_problem::HttpApiProblem::with_title(
            http_api_problem::StatusCode::INTERNAL_SERVER_ERROR,
        )
    };

    Ok(response.to_string())
}
