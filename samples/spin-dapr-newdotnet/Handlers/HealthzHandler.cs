using Spin.Http;

namespace Handlers;

public class HealthzHandler : BaseHandler, IMatcher
{
    public override Task<RequestHandler.Response> HandleAsync(RequestHandler.Request req)
    {
        return Task.FromResult(Ok());
    }

    public static bool IsMatch(string method, string url)
    {
        return method == "GET" && url.StartsWith("/healthz");
    }
}