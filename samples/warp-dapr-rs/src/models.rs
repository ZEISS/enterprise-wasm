#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct OrderItem {
    pub order_item_id: u32,
    pub sku: String,
    pub quantity: u32,
}

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
#[allow(dead_code)]
pub struct Order {
    pub order_id: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order_guid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub first_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_name: Option<String>,
    pub delivery: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub items: Option<Vec<OrderItem>>,
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OutboundMessage<'a> {
    pub data: &'a Order,
    pub operation: String,
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
pub struct OutboxMetadata {
    pub blob_name: String,
}

#[derive(serde::Serialize)]
pub struct OutboxCreate<'a> {
    pub data: &'a Order,
    pub operation: String,
    pub metadata: OutboxMetadata,
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
