## What does this folder contain

Using PSDocs generate Network solution documentation. Deploy [Hub-Spoke](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke) in Azure Subscription and then generate documentation for each of the VNET that is deployed.

## How to execute

```
.\GenerateNetworkDocumentation.ps1 -VirtualNetworkName 'vnet-hub' -OutputPath '.\LetsTryDocumenting\Hub' -TemplatePath '.\LetsTryDocumenting\Templates'
```