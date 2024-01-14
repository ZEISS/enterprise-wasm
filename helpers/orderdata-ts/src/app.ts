import { generateOrders, OrderHeader } from "./generator";
import {
  DaprClient,
  DaprServer,
  CommunicationProtocolEnum,
  DaprInvokerCallbackContent,
  HttpMethod,
} from "@dapr/dapr";
import { compressToBase64, decompressFromBase64 } from "lz-string";

const daprHost = process.env.DAPR_HTTP_HOST || "127.0.0.1";
const daprPort = process.env.DAPR_HTTP_PORT || "3500";

const serverHost = "127.0.0.1";
const serverPort = process.env.PORT || "3000";

async function getHealth(_data: DaprInvokerCallbackContent) {
  return "Ok";
}

async function getTestdata(_data: DaprInvokerCallbackContent) {
  const client = new DaprClient({ daprHost, daprPort });

  const metadata = { blobName: "testdata" };
  let response = {};
  try {
    const compressedOrders = (
      await client.binding.send("testdata", "get", null, metadata)
    ).toString();
    response = JSON.parse(
      decompressFromBase64(compressedOrders),
    ) as OrderHeader[];
  } catch (error: any) {}

  return response;
}

async function postTestdata(data: DaprInvokerCallbackContent) {
  const body = JSON.parse(data.body);
  const count = Number(body["count"]) || 5;

  const client = new DaprClient({ daprHost, daprPort });

  const orders = generateOrders(count);

  const metadata = { blobName: "testdata" };
  const responseBody = { count: orders.length };

  const compressedOrders = compressToBase64(JSON.stringify(orders));
  await client.binding.send("testdata", "create", compressedOrders, metadata);

  return responseBody;
}

async function scheduleTest(data: DaprInvokerCallbackContent) {
  const body = JSON.parse(data.body);
  const scheduleDelayMinutes = Number(body["scheduleDelayMinutes"]) || 0;

  const client = new DaprClient({ daprHost, daprPort });

  const payload = (
    await client.binding.send("testdata", "get", null, {
      blobName: "testdata",
    })
  ).toString();
  const orders = JSON.parse(decompressFromBase64(payload)) as OrderHeader[];

  const metadata = {};
  let responseBody = {};

  if (scheduleDelayMinutes > 0) {
    const utcTime = new Date(Date.now());
    utcTime.setUTCMinutes(utcTime.getUTCMinutes() + scheduleDelayMinutes);
    metadata["ScheduledEnqueueTimeUtc"] = utcTime.toISOString();
    responseBody = { scheduledTimestamp: utcTime.toISOString() };
  }

  orders.forEach((order) => {
    client.binding.send("q-order-ingress", "create", order, metadata);
  });

  return responseBody;
}

async function start() {
  const server = new DaprServer({
    serverHost,
    serverPort,
    communicationProtocol: CommunicationProtocolEnum.HTTP,
    clientOptions: {
      daprHost,
      daprPort,
    },
  });

  await server.invoker.listen("healthz", getHealth);
  await server.invoker.listen("test-data", getTestdata);

  await server.invoker.listen("test-data", postTestdata, {
    method: HttpMethod.POST,
  });

  await server.invoker.listen("schedule-test", scheduleTest, {
    method: HttpMethod.POST,
  });

  await server.start();
}

start().catch((e) => {
  console.error(e);
  process.exit(1);
});
