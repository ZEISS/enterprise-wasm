# Spin with Dapr in Dotnet

# Prerequisites

1. **.NET 7 SDK:**
   - Download and install the .NET 7 SDK from [official .NET download page](https://dotnet.microsoft.com/download/dotnet/7.0).

2. **ASP.NET Runtime:**
   - The project relies on the ASP.NET runtime for web application development.
   - You can download the ASP.NET runtime along with the .NET SDK. If you've installed the .NET SDK, the runtime is usually included.


### build & run on AKS with Azure resources

> deploy infrastructure [from here](../../infra/aks-spin-dapr/README.md)

```
./build.sh
./deploy.sh
./test-spin-dapr-aks.sh
```