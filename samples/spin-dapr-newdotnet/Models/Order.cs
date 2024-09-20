using System.Text.Json.Serialization;

namespace Models;

[JsonSerializable(typeof(Order))]
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
internal partial class OrderSerializerContext : JsonSerializerContext
{
}

public class Order
{
    public int OrderId { get; set; }
    public required string OrderGuid { get; set; }
    public required string Description { get; set; }
    public required string FirstName { get; set; }
    public required string LastName { get; set; }

    public required string Delivery { get; set; }
    
    [JsonIgnore]
    public string DeliveryOutboxName => $"{Delivery.ToLower()}-outbox";
    [JsonIgnore]
    public string DeliveryMethod => Delivery.ToLower();

    [JsonIgnore]
    public bool HasValidDeliveryMethod => Delivery.Equals("express", StringComparison.InvariantCultureIgnoreCase) ||
                                          Delivery.Equals("standard", StringComparison.InvariantCultureIgnoreCase);

    public required List<OrderItem> Items { get; set; }
}