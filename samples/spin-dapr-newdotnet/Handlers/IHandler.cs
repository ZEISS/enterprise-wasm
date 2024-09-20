using static Spin.Http.RequestHandler;

namespace Handlers;

public interface IHandler
{
    public Task<Response> HandleAsync(Request req);
}

public interface IMatcher
{
    static abstract bool IsMatch(string method, string url);
}