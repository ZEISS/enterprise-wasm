namespace Models;

public class OrderItem
{
    public int OrderItemId { get; set; }
    public required string Sku { get; set; }
    public int Quantity { get; set; }
}