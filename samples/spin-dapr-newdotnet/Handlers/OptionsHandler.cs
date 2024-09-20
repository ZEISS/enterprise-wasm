using static Spin.Http.RequestHandler;

namespace Handlers;

public class OptionsHandler : BaseHandler, IMatcher
{
    private const string DesiredMethod = "OPTIONS";
    private static readonly List<string> DesiredRoute = new List<string>
    {
        "/q-order-ingress",
        "q-order-standard-in",
        "q-order-express-in"
    };

    public static bool IsMatch(string method, string url)
    {
        return method == DesiredMethod && DesiredRoute.Contains(url);
    }

    public override Task<Response> HandleAsync(Request req)
    {
        Console.WriteLine("Responding to OPTIONS request with 200");
        return Task.FromResult(Ok());   
    }
}