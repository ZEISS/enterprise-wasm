import { generateOrders } from "./generator";
import {
  DaprClient,
  DaprServer,
  CommunicationProtocolEnum,
  DaprInvokerCallbackContent,
  HttpMethod,
} from "@dapr/dapr";

import { parse } from "querystring";

const daprHost = process.env.DAPR_HTTP_HOST || "127.0.0.1";
const daprPort = process.env.DAPR_HTTP_PORT || "3500";
const serverHost = "127.0.0.1";
const serverPort = process.env.PORT || "3000";

async function getHealth(_data: DaprInvokerCallbackContent) {
  return "Ok";
}

async function getTestdata(data: DaprInvokerCallbackContent) {
  const query = parse(data.query.split("?")[1] || "");
  const count = Number(query["count"]) || 5;

  const orders = generateOrders(count);
  return orders;
}

async function postTestdata(data: DaprInvokerCallbackContent) {
  const body = JSON.parse(data.body);
  const count = Number(body["count"]) || 5;
  const scheduleDelayMinutes = Number(body["scheduleDelayMinutes"]) || 0;

  const client = new DaprClient({ daprHost, daprPort });

  const orders = generateOrders(count);

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

  await server.start();
}

start().catch((e) => {
  console.error(e);
  process.exit(1);
});
