using System.Text;
using SpinHttpWorld.wit.imports.wasi.http.v0_2_0;
using Handlers;
using static Spin.Http.RequestHandler;

namespace SpinHttpWorld.wit.exports.wasi.http.v0_2_0;

public class IncomingHandlerImpl : IIncomingHandler
{
    /// <summary>Handle the specified incoming HTTP request and send a response
    /// via `responseOut`.</summary>
    public static void Handle(ITypes.IncomingRequest request, ITypes.ResponseOutparam responseOut)
    {
        try
        {
            var t = DispatchRequest(request, responseOut);
            Run(t);
        }
        catch (Exception e)
        {
            Console.WriteLine($"Top Level Exception caught {e.Message} {e.StackTrace}");
        }
    }

    private static async Task DispatchRequest(ITypes.IncomingRequest request, ITypes.ResponseOutparam responseOut)
    {
        var req = await Request.FromAsync(request);
        Console.WriteLine($"Dispatching {req.method} {req.uri} with headers:");
        Console.WriteLine("---");
        foreach (var h in req.headers)
        {
            Console.WriteLine($"\t{h.Key}: {Encoding.UTF8.GetString(h.Value)}");
        }
        Console.WriteLine("---");
        var handler = GetRequestHandler(req);
        
        if (handler == null)
        {
            Console.WriteLine($"No handler matches request {req.method} {req.uri}");
            await new Response(404, new Dictionary<string, byte[]> { }, "{}"u8.ToArray()).SetAsync(responseOut);
            return;
        }

        try
        {
            var response = await handler.HandleAsync(req);
            await response.SetAsync(responseOut);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error distributing: {ex.Message}");
            await new Response(500, new Dictionary<string, byte[]> { }, "{}"u8.ToArray()).SetAsync(responseOut);
        }
    }

    private static BaseHandler? GetRequestHandler(Request req)
    {
        Console.WriteLine($"Handling incoming request for {req.method} {req.uri}");
        
        if (DaprMetadataHandler.IsMatch(req.method, req.uri))
        {
            return new DaprMetadataHandler();
        }

        if (HealthzHandler.IsMatch(req.method, req.uri))
        {
            return new HealthzHandler();
        }

        if (OptionsHandler.IsMatch(req.method, req.uri))
        {
            return new OptionsHandler();
        }

        if (DistributionHandler.IsMatch(req.method, req.uri))
        {
            Console.WriteLine(Encoding.UTF8.GetString(req.body!));
            return new DistributionHandler();

        }

        if (ReceiverHandler.IsMatch(req.method, req.uri))
        {
            Console.WriteLine(Encoding.UTF8.GetString(req.body!));
            return new ReceiverHandler();

        }

        return null;
    }
}