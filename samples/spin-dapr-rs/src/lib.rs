use spin_sdk::{
    http::{
        send, IncomingResponse, IntoResponse, Method, Params, Request, RequestBuilder, Response,
        Router,
    },
    http_component, variables,
};

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Order {
    order_id: u32,
    delivery: String,
}

#[derive(serde::Serialize)]
struct OutboundMessage {
    data: Order,
    operation: String,
}

impl OutboundMessage {
    pub fn new(data: Order) -> Self {
        Self {
            data,
            operation: "create".to_owned(),
        }
    }
}

#[http_component]
async fn handle_route(req: Request) -> Response {
    let mut router = Router::new();
    router.get("/healthz", health);
    router.post_async("/q-order-ingress", ingress);
    router.handle(req)
}

fn health(_req: Request, _param: Params) -> anyhow::Result<impl IntoResponse> {
    Ok(Response::new(200, format!("Healthy")))
}

async fn ingress(req: http::Request<String>, _param: Params) -> anyhow::Result<impl IntoResponse> {
    match serde_json::from_str::<Order>(req.body()) {
        Ok(order) => {
            let outbound_message = OutboundMessage::new(order);

            let body = serde_json::to_string(&outbound_message)?;
            println!("body {}", body);

            let dapr_url = variables::get("dapr_url")?;
            let mut url = url::Url::parse(&dapr_url)?;
            url.set_path("v1.0/bindings/q-order-standard-out");

            let request = RequestBuilder::new(Method::Post, url.as_str())
                .body(body)
                .build();

            let response: IncomingResponse = send(request).await?;
            let status = response.status();

            Ok(Response::builder()
                .status(status)
                .header("content-type", "text/plain")
                .body(format!("response status: {status}"))
                .build())
        }

        Err(e) => Ok(Response::builder()
            .status(400)
            .header("content-type", "text/plain")
            .body(format!("invalid Order body {}", e))
            .build()),
    }
}
