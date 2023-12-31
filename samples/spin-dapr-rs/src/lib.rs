use spin_sdk::{
    http::{
        send, IncomingResponse, IntoResponse, Method, Params, Request, RequestBuilder, Response,
        Router,
    },
    http_component, variables,
};

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
#[derive(Clone)]
struct Order {
    order_id: u32,
    delivery: String,
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
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

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct OutboxMetadata {
    blob_name: String,
}

#[derive(serde::Serialize)]
struct OutboxCreate {
    data: Order,
    operation: String,
    metadata: OutboxMetadata,
}

impl OutboxCreate {
    pub fn new(order: Order) -> Self {
        Self {
            data: order.clone(),
            operation: "create".to_owned(),
            metadata: OutboxMetadata {
                blob_name: order.order_id.to_string(),
            },
        }
    }
}

#[http_component]
async fn handle_route(req: Request) -> Response {
    let mut router = Router::new();
    router.get("/healthz", health);
    router.get_async("/dapr-metadata", dapr_metadata);
    router.post_async("/q-order-ingress", distributor);
    router.post_async("/q-order-express-in", receiver);
    router.post_async("/q-order-standard-in", receiver);
    router.handle(req)
}

fn health(_req: Request, _param: Params) -> anyhow::Result<impl IntoResponse> {
    Ok(Response::new(200, format!("Healthy")))
}

async fn dapr_metadata(_req: Request, _param: Params) -> anyhow::Result<impl IntoResponse> {
    let dapr_url = variables::get("dapr_url")?;
    let path = "v1.0/metadata";
    let mut url = url::Url::parse(&dapr_url)?;
    url.set_path(&path);

    let request = RequestBuilder::new(Method::Get, url.as_str()).build();

    let response: Response = send(request).await?;

    Ok(response)
}

async fn distributor(
    req: http::Request<String>,
    _param: Params,
) -> anyhow::Result<impl IntoResponse> {
    match serde_json::from_str::<Order>(req.body()) {
        Ok(order) => {
            let dapr_url = variables::get("dapr_url")?;
            let path = format!(
                "v1.0/bindings/q-order-{}-out",
                &order.delivery.to_lowercase()
            );
            let mut url = url::Url::parse(&dapr_url)?;
            url.set_path(&path);

            let outbound_message = OutboundMessage::new(order);
            let body = serde_json::to_string(&outbound_message)?;
            println!("Distributor body {}", body);

            let request = RequestBuilder::new(Method::Post, url.as_str())
                .body(body)
                .build();

            let response: IncomingResponse = send(request).await?;
            let status = response.status();

            println!("outbound message response: {}", status);

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

async fn receiver(req: http::Request<String>, _param: Params) -> anyhow::Result<impl IntoResponse> {
    match serde_json::from_str::<Order>(req.body()) {
        Ok(order) => {
            let dapr_url = variables::get("dapr_url")?;
            let path = format!("v1.0/bindings/{}-outbox", &order.delivery.to_lowercase());
            let mut url = url::Url::parse(&dapr_url)?;
            url.set_path(&path);

            let outbox_create = OutboxCreate::new(order);
            let body = serde_json::to_string(&outbox_create)?;
            println!("Receiver body {}", body);

            let request = RequestBuilder::new(Method::Post, url.as_str())
                .body(body)
                .build();

            let response: IncomingResponse = send(request).await?;
            let status = response.status();

            println!("outbox response: {}", status);

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
