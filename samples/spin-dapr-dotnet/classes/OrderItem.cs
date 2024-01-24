namespace SpinDotnetDapr;

public class OrderItem
{
    public int orderItemId { get; set; }
    public string sku { get; set; }
    public int quantity { get; set; }

    public OrderItem(int orderItemIdInput, string skuInput, int quantityInput)
    {
        orderItemId = orderItemIdInput;
        sku = skuInput;
        quantity = quantityInput;
    }
}
