using System.Net;
using Fermyon.Spin.Sdk;

namespace SpinDotnetDapr;

public class Handler
{
    [HttpHandler]
    public HttpResponse HandleHttpRequest(HttpRequest request)
    {
        var endpoint = request.Url;
        var method = request.Method;
        var body = request.Body;

        switch ((endpoint, method))
        {      
            // Health Check
            case ("/healthz", _):
                return new HttpResponse { StatusCode = HttpStatusCode.OK };
        
            // Dapr Metadata
            case ("/dapr-metadata", _):
                return DaprMetaData();
        
            // Order Ingress
            case ("/q-order-ingress", Fermyon.Spin.Sdk.HttpMethod.Post):
                return Distributor(body);
            case ("/q-order-ingress", Fermyon.Spin.Sdk.HttpMethod.Options):
                return new HttpResponse { StatusCode = HttpStatusCode.OK };
        
            // Order Express in
            case ("/q-order-express-in", Fermyon.Spin.Sdk.HttpMethod.Post):
                return Receiver(body);
            case ("/q-order-express-in", Fermyon.Spin.Sdk.HttpMethod.Options):
                return new HttpResponse { StatusCode = HttpStatusCode.OK };
        
            // Order Standard in
            case ("/q-order-standard-in", Fermyon.Spin.Sdk.HttpMethod.Post):
                return Receiver(body);
            case ("/q-order-standard-in", Fermyon.Spin.Sdk.HttpMethod.Options):
                return new HttpResponse { StatusCode = HttpStatusCode.OK };
        
            // Default case
            default:
                return new HttpResponse
                {
                    StatusCode = System.Net.HttpStatusCode.NotFound,
                    BodyAsString = $"the specified Endpoint: {endpoint} was not found"
                };
        }
    }

    public HttpResponse DaprMetaData()
    {
        var daprMetadataUrl = GetDaprUrl() + "/v1.0/metadata";
        var daprRequest = new HttpRequest { Url = daprMetadataUrl };

        try
        {
            var response = HttpOutbound.Send(daprRequest);
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.OK,
                BodyAsString = response.Body.AsString()
            };
        }
        catch (Exception e)
        {
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.InternalServerError,
                BodyAsString = e.ToString()
            };
        }
    }

    public HttpResponse Distributor(Optional<Buffer> body)
    {
        string? daprUrl = GetDaprUrl();
        Console.WriteLine("Dapr base url: " + daprUrl);

        string bodyString = body.AsString();
        Console.WriteLine(bodyString);

        string delivery = GetValueFromJson(bodyString, "delivery");
        System.Console.WriteLine(delivery);
        System.Console.WriteLine("delivery is: " + delivery);

        string deliveryLower = ConvertToLowercase(delivery);
        Console.WriteLine("sending to " + deliveryLower);

        var request = new HttpRequest
        {
            Url = $"{daprUrl}/v1.0/bindings/q-order-{deliveryLower}-out",
            Headers = HttpKeyValues.FromDictionary(new Dictionary<string, string>
            {
                { "Content-Type", "application/json" }
            }),
            Body = Optional.From(Buffer.FromString("{\"operation\": \"create\", \"data\":" + bodyString + "}")),
            Method = Fermyon.Spin.Sdk.HttpMethod.Post
        };

        try
        {
            System.Console.WriteLine("try sending out request");
            var response = HttpOutbound.Send(request);
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.OK,
                BodyAsString = bodyString + response.BodyAsString
            };
        }
        catch (Exception e)
        {
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.InternalServerError,
                BodyAsString = e.ToString()
            };
        }
    }

    public HttpResponse Receiver(Optional<Buffer> body)
    {
        string? daprUrl = GetDaprUrl();
        Console.WriteLine("Dapr base url: " + daprUrl);

        string bodyString = body.AsString();
        Console.WriteLine(bodyString);
        GetValueFromJson(bodyString, "delivery");

        var delivery = GetValueFromJson(bodyString, "delivery");
        System.Console.WriteLine("delivery is: " + delivery);
        string deliveryLower = ConvertToLowercase(delivery);
        Console.WriteLine("sending to " + deliveryLower);

        string orderId = GetValueFromJson(bodyString, "orderId");
        Console.WriteLine("orderId: " + orderId);

        string operationString = "{\"operation\": \"create\", \"data\":" + bodyString + ", \"metadata\":{\"blobName\":\"" + orderId + "\"}}";

        var request = new HttpRequest
        {
            Url = $"{daprUrl}/v1.0/bindings/{deliveryLower}-outbox",
            Headers = HttpKeyValues.FromDictionary(new Dictionary<string, string>
            {
                { "Content-Type", "application/json" }
            }),
            Body = Optional.From(Buffer.FromString(operationString)),
            Method = Fermyon.Spin.Sdk.HttpMethod.Post
        };
        try
        {
            System.Console.WriteLine("try sending out request");
            var response = HttpOutbound.Send(request);
            Console.WriteLine(response.BodyAsString);
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.OK,
                BodyAsString = operationString + response.BodyAsString
            };
        }
        catch (Exception e)
        {
            return new HttpResponse
            {
                StatusCode = HttpStatusCode.InternalServerError,
                BodyAsString = e.ToString()
            };
        }
    }

    public string GetDaprUrl()
    {
        return SpinConfig.Get("dapr_url");
    }

    public string GetValueFromJson(string jsonString, string key)
    {
        int keyIndex = GetSubstringIndex(jsonString, "\"" + key + "\":");
        if (keyIndex == -1)
        {
            return "";
        }
        string substring = jsonString.Substring(keyIndex + key.Length + 3);
        int endIndex = substring.IndexOfAny(new char[] { ',', '}' });
        if (endIndex == -1)
        {
            return "";
        }
        string value = substring.Substring(0, endIndex).Trim(' ', '"');
        return value;
    }

    public int GetSubstringIndex(string mainString, string substring)
    {
        for (int i = 0; i <= mainString.Length - substring.Length; i++)
        {
            // Check if substring matches
            if (IsSubstringAtIndex(mainString, substring, i))
            {
                return i;
            }
        }

        return -1;
    }

    public bool IsSubstringAtIndex(string mainString, string substring, int startIndex)
    {
        for (int j = 0; j < substring.Length; j++)
        {
            // Check if characters match
            if (mainString[startIndex + j] != substring[j])
            {
                return false;
            }
        }

        return true;
    }

    public string ConvertToLowercase(string input)
    {
        char[] characters = input.ToCharArray();

        for (int i = 0; i < characters.Length; i++)
        {
            // Check if character is uppercase letter (ASCII range)
            if (characters[i] >= 'A' && characters[i] <= 'Z')
            {
                // Convert uppercase to lowercase
                characters[i] = (char)(characters[i] + 32);
            }
        }

        return new string(characters);
    }
}