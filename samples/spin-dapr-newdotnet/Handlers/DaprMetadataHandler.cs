using Helpers;
using static Spin.Http.RequestHandler;

namespace Handlers;

public class DaprMetadataHandler : BaseHandler, IMatcher
{
    public static bool IsMatch(string method, string url) => url == "/dapr-metadata";

    public override async Task<Response> HandleAsync(Request req)
    {
        var url = $"{Spin.SDK.Variables.Get(Constants.Variables.DaprUrl)}/v1.0/metadata";
        using var client = new HttpClient();
        try
        {
            await using var stream = await client.GetStreamAsync(url);
            using var ms = new MemoryStream();
            await stream.CopyToAsync(ms);
            return new Response(200, new Dictionary<string, byte[]>
            {
                {
                    Constants.HttpHeaderNames.ContentType,
                    "application/json"u8.ToArray()
                }
            }, ms.ToArray());
        }
        catch (Exception e)
        {
            return InternalServerError(e.Message);
        }
    }
}