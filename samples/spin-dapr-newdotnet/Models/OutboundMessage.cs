using System.Text.Json.Serialization;
using Helpers;
namespace Models;

[JsonSerializable(typeof(OutboundMessage))]
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
internal partial class OutboundMessageSerializerContext : JsonSerializerContext
{
}

public class OutboundMessage
{
    public required Order Data { get; set; }
    public required string Operation { get; set; }
    public Metadata? Metadata { get; set; }
    public static OutboundMessage From(Order o) =>
        new()
        {
            Data = o,
            Operation = Constants.DaprOperations.Create,
            Metadata = new Metadata { BlobName = $"{o.OrderId}" }
        };
}