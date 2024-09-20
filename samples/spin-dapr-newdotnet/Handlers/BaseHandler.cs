using Helpers;
using Handlers;
using Spin.Http;
using static Spin.Http.RequestHandler;

namespace Handlers;

public abstract class BaseHandler : IHandler
{
    protected static RequestHandler.Response InternalServerError(string message)
    {
        return new Response(500, new Dictionary<string, byte[]>(), System.Text.Encoding.UTF8.GetBytes(message));
    }

    protected static RequestHandler.Response NotFound()
    {
        return FromStatusCode(404);
    }

    protected static RequestHandler.Response BadRequest()
    {
        return FromStatusCode(400);
    }

    protected static RequestHandler.Response Ok()
    {
        return FromStatusCode(200);
    }

    private static RequestHandler.Response FromStatusCode(ushort statusCode)
    {
        return new RequestHandler.Response(statusCode, new Dictionary<string, byte[]>()
        {
            {
                Constants.HttpHeaderNames.ContentType,
                "application/json"u8.ToArray()
            }
        }, "{}"u8.ToArray());
    }

    public abstract Task<Response> HandleAsync(Request req);
}