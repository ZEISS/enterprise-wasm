namespace SpinDotnetDapr;

public class Order
{
    public int orderId { get; set; }
    public string orderGuid { get; set; }
    public string description { get; set; }
    public string firstName { get; set; }
    public string lastName { get; set; }
    public string delivery { get; set; }
    public OrderItem[] items { get; set; }

    public Order(int orderIdInput, string orderGuidInput, string descriptionIntput, string firstNameInput, string lastNameInput, string deliveryInput, OrderItem[] itemsInput)
    {
        orderId = orderIdInput;
        orderGuid = orderGuidInput;
        description = descriptionIntput;
        firstName = firstNameInput;
        lastName = lastNameInput;
        delivery = deliveryInput;
        items = itemsInput;
    }
}
