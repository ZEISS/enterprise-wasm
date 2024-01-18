namespace SpinDotnetDapr;

public class OrderItem
{
    public int orderId { get; set; }
    public string sku { get; set; }
    public int quantity { get; set; }

    public OrderItem(int orderIdInput, string skuInput, int quantityInput)
    {
        orderId = orderIdInput;
        sku = skuInput;
        quantity = quantityInput;
    }
}
