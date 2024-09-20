using System.Net.Http.Json;
using System.Text.Json;
using Helpers;
using Models;
using static Spin.Http.RequestHandler;

namespace Handlers;

public class ReceiverHandler : BaseHandler, IMatcher
{
    private static readonly List<string> DesiredRoute = new List<string>
    {
        "/q-order-standard-in",
        "/q-order-express-in"
    };
    public static bool IsMatch(string method, string url)
    {
        return method == "POST" && DesiredRoute.Contains(url);
    }
    
    public override async Task<Response> HandleAsync(Request req)
    {
        if (req.body == null)
        {
            Console.WriteLine("No Payload provided");
            return BadRequest();
        }

        var order = JsonSerializer.Deserialize(req.body, OrderSerializerContext.Default.Order);
        if (order is not { HasValidDeliveryMethod: true })
        {
            Console.WriteLine("Invalid Delivery Method provided");
            return BadRequest();
        }

        await ReceiveMessage(order);
        return Ok();
    }

    private async Task ReceiveMessage(Order order)
    {
        var url = BuildReceiverUrl(order.DeliveryMethod);
        using var client = new HttpClient();
        var outboundMessage = OutboundMessage.From(order);

        var res = await client.PostAsJsonAsync(url, outboundMessage,
            OutboundMessageSerializerContext.Default.OutboundMessage);
        Console.WriteLine($"Received {res.StatusCode} from distributing message with delivery method {order.Delivery}");
    }
    
    private static string BuildReceiverUrl(string deliveryMethod) =>
        $"{Spin.SDK.Variables.Get(Constants.Variables.DaprUrl)}/v1.0/bindings/{deliveryMethod}-outbox";
}