import { DaprClient, DaprServer, CommunicationProtocolEnum } from "@dapr/dapr";

const daprHost = process.env.DAPR_HTTP_HOST || "127.0.0.1";
const daprPort = process.env.DAPR_HTTP_PORT || "3500";

const serverHost = "127.0.0.1";
const serverPort = process.env.PORT || "3000";

async function getHealth() {
  return "Ok";
}

async function getMeta() {
  const client = new DaprClient({ daprHost, daprPort });
  const metadata = await client.metadata.get();
  return metadata;
}

async function distributor(order) {
  console.log(order);
  const client = new DaprClient({ daprHost, daprPort });
  return await client.binding.send(
    `q-order-${order.delivery.toLowerCase()}-out`,
    "create",
    order,
  );
}

async function receiver(order) {
  console.log(order);
  const client = new DaprClient({ daprHost, daprPort });
  return await client.binding.send(
    `${order.delivery.toLowerCase()}-outbox`,
    "create",
    order,
    {
      blobName: order.orderId.toString(),
    },
  );
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
  await server.invoker.listen("dapr-metadata", getMeta);

  await server.binding.receive("q-order-ingress", distributor);
  await server.binding.receive("q-order-express-in", receiver);
  await server.binding.receive("q-order-standard-in", receiver);

  await server.start();
}

console.log(`Server at ${serverHost}:${serverPort}`);
console.log(`Dapr at ${daprHost}:${daprPort}`);

start().catch((e) => {
  console.error(e);
  process.exit(1);
});
