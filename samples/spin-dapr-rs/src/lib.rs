use http::Request;
use spin_sdk::{
    http::{
        send, IncomingResponse, IntoResponse, Json, Method, Params, RequestBuilder, Response,
        Router,
    },
    http_component, variables,
};

#[derive(serde::Deserialize, Debug)]
struct Order {
    name: String,
}

#[http_component]
async fn handle_route(req: Request<()>) -> Response {
    let mut router = Router::new();
    router.get("/healthz", health);
    router.post_async("/q-order-ingress", ingress);
    router.handle(req)
}

fn health(_req: Request<()>, _param: Params) -> anyhow::Result<impl IntoResponse> {
    Ok(Response::new(200, format!("Healthy")))
}

async fn ingress(
    req: http::Request<Json<Order>>,
    _param: Params,
) -> anyhow::Result<impl IntoResponse> {
    let dapr_url = variables::get("dapr_url")?;

    println!("name: {}", req.body().name);
    println!("dapr_url: {}", dapr_url);

    let request = RequestBuilder::new(Method::Post, "/v1.0/bindings/q-order-standard")
        .uri(dapr_url)
        .method(Method::Post)
        .body("xx")
        .build();

    let response: IncomingResponse = match send(request).await {
        Ok(response) => response,
        Err(_) => panic!("error when calling outbound binding"),
    };

    let status = response.status();
    Ok(Response::builder()
        .status(200)
        .header("content-type", "text/plain")
        .body(format!("response status: {status}"))
        .build())
}
