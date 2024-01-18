namespace SpinDotnetDapr;

public class Metadata
{
    public string blobName { get; set; }
    public Metadata(string blobNameInput)
    {
        blobName = blobNameInput;
    }
}
