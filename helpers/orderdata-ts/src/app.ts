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
const serverPort = "3000";

async function getTestdata(data: DaprInvokerCallbackContent) {
  console.log(data.query);
  const query = parse(data.query.split("?")[1] || "");
  const count = Number(query["count"]) || 5;

  const orders = generateOrders(count);
  return orders;
}

async function postTestdata(data: DaprInvokerCallbackContent) {
  const count = Number(JSON.parse(data.body)["count"]) || 5;

  const client = new DaprClient({ daprHost, daprPort });

  const orders = generateOrders(count);

  orders.forEach((order) => {
    client.binding.send("q-order-ingress", "create", order);
  });

  return orders;
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
