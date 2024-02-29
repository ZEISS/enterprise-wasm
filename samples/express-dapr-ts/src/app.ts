import {
  DaprClient,
  DaprServer,
  CommunicationProtocolEnum,
  DaprInvokerCallbackContent,
  HttpMethod,
} from "@dapr/dapr";

const daprHost = process.env.DAPR_HTTP_HOST || "127.0.0.1";
const daprPort = process.env.DAPR_HTTP_PORT || "3500";

const serverHost = "127.0.0.1";
const serverPort = process.env.PORT || "3000";

async function getHealth(_data: DaprInvokerCallbackContent) {
  return "Ok";
}

async function getMeta(_data: DaprInvokerCallbackContent) {
  const client = new DaprClient({ daprHost, daprPort });
  const metadata = await client.metadata.get();
  return metadata;
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

  await server.start();
}

start().catch((e) => {
  console.error(e);
  process.exit(1);
});
