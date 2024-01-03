use spin_sdk::{
    http::{
        send, IncomingResponse, IntoResponse, Method, Params, Request, RequestBuilder, Response,
        Router,
    },
    http_component, variables,
};

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

            let outbound_message = OutboundMessage::new(&order);
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

            let outbox_create = OutboxCreate::new(&order);
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
