using Aspire.Hosting.Dapr;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

var builder = DistributedApplication.CreateBuilder(args);
builder.AddDapr();

var orderIngressQueue = builder.AddDaprComponent("q-order-ingress", "bindings.azure.servicebusqueues", new DaprComponentOptions{
    LocalPath = "./dapr-components/receiver-components/servicebus-q-order-ingress.yaml"
});

var expressOutbox = builder.AddDaprComponent("express-outbox", "bindings.azure.blobstorage", new DaprComponentOptions
{
    LocalPath = "./dapr-components/distributor-express-components/express-outbox.yaml"
});

var standardOutbox = builder.AddDaprComponent("standard-outbox", "bindings.azure.blobstorage", new DaprComponentOptions{
    LocalPath = "./dapr-components/distributor-standard-components/standard-outbox.yaml"
});

var receiverDaprPort = 3501;
var receiverDaprUrl = $"http://localhost:{receiverDaprPort}";
var distributorExpressDaprPort = 3502;
var distributorExpressDaprUrl = $"http://localhost:{receiverDaprPort}";
var distributorStandardDaprPort = 3503;
var distributorStandardDaprUrl = $"http://localhost:{receiverDaprPort}";


builder.AddSpinApp("receiver", "../../samples/spin-dapr-ts", 3001)
    .WithSpinEnvironment("dapr_url", receiverDaprUrl)
    .WithDaprSidecar(new DaprSidecarOptions{
        DaprHttpPort = receiverDaprPort
    }).WithReference(orderIngressQueue);

builder.AddSpinApp("distributor-express", "../../samples/spin-dapr-ts", 3002)
    .WithSpinEnvironment("dapr_url", distributorExpressDaprUrl)
    .WithDaprSidecar(new DaprSidecarOptions{
        DaprHttpPort = distributorExpressDaprPort
    }).WithReference(expressOutbox);

builder.AddSpinApp("distributor-standard", "../../samples/spin-dapr-ts", 3003)
    .WithSpinEnvironment("dapr_url", distributorStandardDaprUrl)
    .WithDaprSidecar(new DaprSidecarOptions{
        DaprHttpPort = distributorStandardDaprPort
    }).WithReference(standardOutbox);

builder.Build().Run();