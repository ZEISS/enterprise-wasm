import {
  HandleRequest,
  HttpRequest,
  HttpResponse,
  Router,
  Config,
} from "@fermyon/spin-sdk";

const encoder = new TextEncoder();
const decoder = new TextDecoder();
const router = Router();

router.get("/healthz", () => ({ status: 200 }));
router.get("/dapr-metadata", () => dapr_meta());
router.options("/q-order-ingress", () => ({ status: 200 }));
router.post("/q-order-ingress", (_, body) => distributor(body));
router.options("/q-order-express-in", () => ({ status: 200 }));
router.post("/q-order-express-in", (_, body) => receiver(body));
router.options("/q-order-standard-in", () => ({ status: 200 }));
router.post("/q-order-standard-in", (_, body) => receiver(body));
router.all("*", () => ({
  status: 404,
  body: encoder.encode("Not found"),
}));

async function dapr_meta(): Promise<HttpResponse> {
  const dapr_url = Config.get("dapr_url");
  const url = `${dapr_url}/v1.0/metadata`;

  try {
    const response = await fetch(url);
    const body = await response.json();

    return {
      status: 200,
      body: encoder.encode(JSON.stringify(body, null, 2)),
    };
  } catch (e) {
    return {
      status: 500,
      body: encoder.encode(JSON.stringify(e, null, 2)),
    };
  }
}

async function distributor(body: ArrayBuffer): Promise<HttpResponse> {
  try {
    const order = JSON.parse(decoder.decode(body));

    const dapr_url = Config.get("dapr_url");
    const url = `${dapr_url}/v1.0/bindings/q-order-${order.delivery.toLowerCase()}-out`;

    await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: encoder.encode(
        JSON.stringify(
          {
            operation: "create",
            data: order,
          },
          null,
          2,
        ),
      ),
    });

    return {
      status: 200,
      body: encoder.encode(JSON.stringify(order, null, 2)),
    };
  } catch (e) {
    return {
      status: 500,
      body: encoder.encode(JSON.stringify(e, null, 2)),
    };
  }
}

async function receiver(body: ArrayBuffer): Promise<HttpResponse> {
  try {
    const order = JSON.parse(decoder.decode(body));

    const dapr_url = Config.get("dapr_url");
    const url = `${dapr_url}/v1.0/bindings/${order.delivery.toLowerCase()}-outbox`;

    const operation = JSON.stringify(
      {
        operation: "create",
        data: order,
        metadata: {
          blobName: order.orderId.toString(),
        },
      },
      null,
      2,
    );

    await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: encoder.encode(operation),
    });

    return {
      status: 200,
      body: encoder.encode(JSON.stringify(order, null, 2)),
    };
  } catch (e) {
    return {
      status: 500,
      body: encoder.encode(JSON.stringify(e, null, 2)),
    };
  }
}

export const handleRequest: HandleRequest = async function (
  request: HttpRequest,
): Promise<HttpResponse> {
  return router.handleRequest(request, request.body);
};
