namespace SpinDotnetDapr;

public class Operation
{
    public string operation { get; set; }
    public Order data { get; set; }
    public Metadata metadata { get; set; }
    public Operation(string operationInput, Order dataInput, Metadata metadataInput)
    {
        operation = operationInput;
        data = dataInput;
        metadata = metadataInput;
    }
}
