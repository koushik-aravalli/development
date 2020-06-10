# Virtual Network <solutionshortname><environmentnr(2)>-vnet

[[_TOC_]]

## Version Context

> **Note:** Consult the [Markdown documentation](https://docs.microsoft.com/en-us/contribute/how-to-write-use-markdown) for guidance on how to use Markdown.
> **Note:** Visual Studio Code tip: use `Ctrl + K + V` to open preview slide of the this readme file. This will show what the markdown code will look like.
> **Note:** Visual Studio Code tip: install the exstension `markdownlint` from the Extensions Marketplace (`Crtl + Shift + X`) to provide you with tips to improve your Markdown writing.
> **Note:** whenever a `[ ]` is used, a checkbox is created (visuable in preview mode). Use `[X]` to check the boxes which apply to your Network Solution.
> **Note:** fill in all the details and remove the **Notes:** which are listed in this template. After a `:` a space ` ` is expected.

- Customer Workload:
- Customer Contact:
- Solution Version:

### Environment Details

> **Note:** for the `Virtual Network Name`, only use `<solutionshortname><environmentnr(2)>`. The environment character and suffix `-vnet` will be added when generating the parameter files. For example use `cbsp01` as the Virtual Network Name. If the Resource Group ServiceName differentiates from the `Virtual Network Name`, then the `ServiceName` must be filled in, otherwise the `Virtual Network Name` will be used.
> **Note:** the `serviceName` is the resourcegroup name of the Network Solution. Only use the `<solutionshortname>` here. The environment character and suffix `-vnets-<environment(1)>-rg` will be added when generating the parameter files. For example, use `cbsp` as the ServiceName.
> **Note:** the `Subscription` is the Subscription name to deploy the network solution based on the DT/AP workloads. Replace `VDCxS` with the Subscription name ex: VDC3S or VDC10S

- Subscription:
    - [ ] Management
    - [ ] Engineering
    - [ ] VDC1
    - [ ] VDCxS
- Virtual Network Name:
- Environment
    - [ ] Engineering
    - [ ] Development
    - [ ] Test
    - [ ] Acceptance
    - [ ] Production
- ServiceName:
- Location: westeurope
- Allowed Locations: westeurope, northeurope
- Business Application CI:
- Billing code:
- Provider: CBSP Azure
- AppName:
- CIA:
- ContactMail: cbsp-azure@nl.abnamro.com
- ContactPhone: +31203830584

## Solution Specifics

### Design Decisions

## Virtual Network

> **Note:** [IPAM List](https://abnamro.sharepoint.com/:x:/r/sites/cbspazure/_layouts/15/doc2.aspx?sourcedoc=%7Bf36deae5-e0e8-4a31-b781-6a4ac8b77380%7D&action=default&uid=%7BF36DEAE5-E0E8-4A31-B781-6A4AC8B77380%7D&ListItemId=280&ListId=%7BF02FEB88-677C-495B-8853-BA5EDF5F911C%7D&odsp=1&env=prod)
> **Note:** only one DNS option must be selected. The options are: the default Azure DNS server (Azure DNS), the CBSP Azure custom DNS servers (Azure ADDS DNS), or a workload specific cutsom DNS server (Other)
> **Note:** if you're planning on adding the Azure Kubernetes Service Network Solution to your VNet, use the naming convention `aks<sequencenr(2)>-subnet`. So for example, if this is the first AKS subnet in your Network Solution, use `aks01-subnet`.
> **Note:** if you're planning on adding the Azure Databricks Network Solution to your VNet, use the naming convention `adbpublic<sequencenr(2)>-subnet` for the public subnet, and `adbprivate<sequencenr(2)-subnet>` for the private subnet. So for example, if this is the first ADB solution in your Network Solution, use `adbpublic01-subnet` and `adbprivate01-subnet`.

- Address Space: <IP address space 1>, <IP address space x>
- [ ] Azure DNS
- [ ] Azure ADDS DNS (`10.232.2.4` and `10.232.2.5`)
- [ ] On-prem Infoblox (`10.124.237.66` and `10.124.226.228`)
- [ ] Other:

> **Note:** Fill in all subnets in the table below, and when using Service Endpoint(s) use the following syntax as example to allow all locations: `Microsoft.Sql`
To only allow specific location use: `Microsoft.Sql:westeurope, northeurope`
If multiple Service Endpoints are used use `<br />` with example: `Microsoft.Sql:westeurope, northeurope<br />Microsoft.Storage:westeurope, northeurope`
Within the [Design Decisions](#design-decisions) describe the solution reason why this needs to be enabled.
See [Virtual Network Service Endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) for a list of Service Endpoints.

|Subnet name|Address Space|Service Endpoint|
|-|-|-|

> **Note:** For [Kubernetes Service v1](https://dev.azure.com/cbsp-abnamro/Azure/_wiki/wikis/Azure.wiki?pagePath=%2FProducts%2FKubernetes%20Service%20v1&pageId=539&wikiVersion=GBwikiMaster) the option `Enforce Subnet-NSG-RT relationship` must be enabled/checked. This option enforces the relationship between each subnet and the Network Security Group and if applicable also the Route Table.

- [ ] Enforce Subnet-NSG-RT relationship

### Peering

- Default HUB-Spoke deployment model (HUB in Management, Spoke in selected WL subnets (e.g. VDC2S))

- [ ] Hub/Spoke
- [ ] Spoke/Spoke
    - [ ] Peering to `nsp02-e-vnet` in `nsp02-vnets-e-rg`, `0a1e54a3-58b3-40f8-82bd-efd7844068a5`
    - [ ] Peering to `infra01-vnet` in `infra-vnets-p-rg`, `b658ffad-30c7-4be6-881c-e3dc1f6520af`
    - [ ] Peering to `<Peer VNet name>` in `Peer VNet Resource Group`, `Peer VNet Subscription Id`

### Subnet

### Delegation

> **Note:** when deploying a Network Solution in VDC2S (Self-Service) a delegation model needs to be added. For associating NIC's with a specific subnet, the SPN used for deployment needs to have `Virtual Machine Contributor` or equivalent rights. In order to enable the Firewall on Storage account in combination with Service Endpoint enabled, 'Storage Contributor' rights are needed for the SPN. In order for the customer to be able to see the deployed Network Solution, `Reader` rights are needed on the resource group.

- [ ] Resource Group: <Azure AD Group Name> `Azure AD Group Object Id`: `<Role Assignement Name>`
- [ ] Subnet Join for <Subnet name>: <Service Principal Name> `<Service Principal Object Id>`: `<Role Assignment Name>`
- [ ] Subnet Join for <Subnet name>: <Service Principal Name> `<Service Principal Object Id>`: `CBSP Azure Virtual Network Subnet Join [Production]`

> **Note:** the below role assignments are needed for AKS. As a pre-requisite, a Kubernetes [Service Prinicpal needs to be created](https://dev.azure.com/cbsp-abnamro/Azure/_wiki/wikis/Azure.wiki?pagePath=%2FProducts%2FKubernetes%20Service%20v1%2FUsage%20Guidance&wikiVersion=GBwikiMaster&pageId=542&anchor=pre-requisites)

- [ ] Subnet Join for <aksXX-subnet>: <Service Prinicpal Name (DevOps)> `<Service Principal Object Id>`: `CBSP Azure Kubernetes Service Networking [Production]`
- [ ] Subnet Join for <aksXX-subnet>: <Service Prinicpal Name (Kubernetes)> `<Service Principal Object Id>`: `CBSP Azure Kubernetes Service Networking [Production]`

### Route Tables

> **Note:** if connectivity to Azure AD Services (part of Microsoft 365) is required on a subnet, fill in the name of the subnet at `<Subnet name>` and check both boxes. The specific routes to allow for connectivity to Azure AD Services will be added to the route table when generating the parameter files. The M365-Comon ID 56 routes checkbox no longer applies for Development or Test vNets. Use the appropriate route table for the Azure Firewall deployed in hubwe07.

- [ ] M365-Common ID 56: 10.232.1.68
    - [ ] <Subnet name>

List of [M365-Common ID 56 Required](https://docs.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges#microsoft-365-common-and-office-online) routes.

> **Note:** if a subnet needs routes other then the routes needed for connectivity to Azure AD services, fill in the table below.

#### RT <Subnet name>

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|

> **For workloads in Development and Test that need connectivity to Azure AD Services**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Default-Route-NSP|0.0.0.0/0|VirtualAppliance|10.232.110.196|

#### RT <adbpublicXX-subnet>

> **Note:** below Route Table for the Public subnet for the Azure Databricks Network Solution in a custom VNet. Since specific direct routes for Azure Databricks [Webbapp and Control Plane](https://docs.azuredatabricks.net/administration-guide/cloud-configurations/azure/udr.html) are required, the rules in this RouteTable shouldn't be changed. Use the exact RT below when adding the ADB Network Solution to your VNet. This allows for secure, communicaton with the Control Plane/WebApp.

> **For workloads in Development and Test**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Databricks-Control-Plane-Webapp|52.232.19.246/32|Internet||
|Databricks-Control-Plane-NAT|23.100.0.135/32|Internet||
|Default-Route-NSP|0.0.0.0/0|VirtualAppliance|10.232.110.196|

> **For workloads in Acceptance and Production**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Databricks-Control-Plane-Webapp|52.232.19.246/32|Internet||
|Databricks-Control-Plane-NAT|23.100.0.135/32|Internet||
|Default-Route-NSP|0.0.0.0/0|VirtualAppliance|10.232.1.4|

#### RT <adbprivateXX-subnet>

> **Note:** Below Route Table for the Private subnet for the Azure Databricks Network Solution in a custom VNet. Since communication with the Control Plane/WebApp is only required for `<adbpublicXX-subnet>`, a null route is configered on `<adbprivateXX-subnet>` by setting the nextHopType of the default route to `None` on `<adbprivateXX-subnet>-routetable`. This ensures all outbound traffic is dropped. Only traffic to the CBSP Azure custom DNS Servers is allowed. The rules in this RouteTable shouldn't be changed. Use the exact RT below when adding the ADB Network Solution to your VNet.

> **For workloads in Development and Test**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Route-to-DNS-DC1|10.232.2.4/32|VirtualAppliance|10.232.10.132|
|Route-to-DNS-DC2|10.232.2.5/32|VirtualAppliance|10.232.10.132|
|Default-Null-Route|0.0.0.0/0|None||

> **For workloads in Acceptance and Production**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Route-to-DNS-DC1|10.232.2.4/32|VirtualAppliance|10.232.10.4|
|Route-to-DNS-DC2|10.232.2.5/32|VirtualAppliance|10.232.10.4|
|Default-Null-Route|0.0.0.0/0|None||

#### RT <aksXX-subnet>

> **Note:** below Route Table for the <aksXX-subnet>. This RT shouldn't be changed, since this is part of the AKS network topology.

> **For workloads in Development and Test**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|DefaultRouteNSP|0.0.0.0/0|VirtualAppliance|10.232.110.196||

> **For workloads in Acceptance and Production**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Default-Route-NSP|0.0.0.0/0|VirtualAppliance|10.232.1.4||

#### RT <appgwXX-subnet>
  **For Application Gateway v3**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|ApplicationGatewayBackendServices|0.0.0.0/0|Internet|

#### RT <appgwXX-subnet>
  **For Application Gateway v4**
> **Note:** The `appgwXX-subnet` does not support a user defined route. Please do not create a UDR as this will break the deployment of the Application Gateway v4. 

#### RT <appserviceXX-subnet>

> **For workloads in Development and Test**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|DefaultRouteNSP|0.0.0.0/0|VirtualAppliance|10.232.110.196||

> **For workloads in Acceptance and Production**

|Name|Address Prefix|Next Hop Type| Next Hop IP Address|
|-|-|-|-|
|Default-Route-NSP|0.0.0.0/0|VirtualAppliance|10.232.1.4||

### Network Security Group

> **Note:** Visual Studio Code tip: to replace `<Address Prefix>` use `Ctrl + H`, enter `<Address Prefix>` in the first field and type the replacement IP Address Suffix in the second field. Select the table below and press `Alt + L`, use `Ctrl + Alt + Enter` to replace all occurrences within the selected text.
> **Note:** duplicate the next section when there are multiple subnets and use the hint in the note above.

#### NSG <Subnet name>

> **Note:** below is the default base rule set, remove the Inbound HTTPS/SSH/RDP (201/202/203) if not required. If no outbound traffic to On-Prem is required, remove rule 103 & 104. If no outbound traffic to Internet and Azure Public is required, remove rule 104 & 105.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|Default VNet rules|Allow Inbound **ALL** IntraSubnet traffic between nodes in the <subnet name>|Inbound|100|Allow|<Address Prefix>|<Address Prefix>|*|*|
|Default VNet rules|Deny Inbound **ALL** from Azure Private IP space except for previously expilicitly defined rules with higher priority|Inbound|200|Deny|10.232.0.0/16|<Address Prefix>|*|*|
|Default VNet rules|Allow Inbound **HTTPS (TCP 443)** from ABN AMRO internally|Inbound|201|Allow|10.0.0.0/8|<Address Prefix>|*|443|
|Default VNet rules|Allow Inbound **SSH (TCP 22)** from ABN AMRO internally|Inbound|202|Allow|10.0.0.0/8|<Address Prefix>|*|22|
|Default VNet rules|Allow Inbound **RDP (TCP 3389)** from ABN AMRO internally|Inbound|203|Allow|10.0.0.0/8|<Address Prefix>|*|3389|
|Default VNet rules|Deny Inbound **ALL** other traffic|Inbound|1000|Deny|*|*|*|*|
|Default VNet rules|Allow Outbound **ALL** IntraSubnet traffic between nodes in the <subnet name>|Outbound|100|Allow|<Address Prefix>|<Address Prefix>|*|*|
|Default VNet rules|Allow Outbound **ALL** from <subnet name> to AzurePrivateInfraServices|Outbound|101|Allow|<Address Prefix>|10.232.0.0/24, 10.232.1.0/24, 10.232.2.0/24, 10.232.19.0/24|*|*|
|Default VNet rules|Deny Outbound **ALL** to Azure Private IP space except for previously explicitly defined rules with higher priority|Outbound|102|Deny|<Address Prefix>|10.232.0.0/16|*|*|
|Default VNet rules|Allow Outbound **TCP 8080** to On-Prem Proxy LoadBalancer IP|Outbound|103|Allow|<Address Prefix>|10.120.118.50/32|*|8080|
|Default VNet rules|Allow Outbound **ALL** to Internal IP space|Outbound|104|Allow|<Address Prefix>|10.0.0.0/8|*|*|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space|Outbound|105|Allow|<Address Prefix>|AzureCloud|*|80,443|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` Public IP space|Outbound|106|Allow|<Address Prefix>|Internet|*|80,443|

> **Note:** Service Endpoint template rules. Add this rules to the NSG if outbound traffic to one of the service tags is required.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|<workload> Specific rules|Allow Outbound **HTTP+S (TCP 80, 443)** to Azure Storage endpoints in West Europe by the use of service tag `Storage.WestEurope`|Outbound|<priority>|Allow|<Address Prefix>|Storage.WestEurope|*|80,443|
|<workload> Specific rules|Allow Outbound **HTTP+S (TCP 80, 443)** to Azure Storage endpoints in North Europe by the use of service tag `Storage.NorthEurope`|Outbound|<priority>|Allow|<Address Prefix>|Storage.NorthEurope|*|80,443|
|<workload> Specific rules|Allow Outbound **TCP 1433 + 11000-11999** to all West Europe Azure SQL Database endpoints by the use of service tag `Sql.WestEurope`|Outbound|<priority>|Allow|<Address Prefix>|Sql.WestEurope|*|1433,11000-11999|
|<workload> Specific rules|Allow Outbound **TCP 1433 + 11000-11999** to all North Europe Azure SQL Database endpoints by the use of service tag `Sql.NorthEurope`|Outbound|<priority>|Allow|<Address Prefix>|Sql.NorthEurope|*|1433,11000-11999|

> **Note:** Azure Load Balancer TCP Probe template rule. Add this rule to the NSG if inbound traffic from the AzureLoadBalancer service tag is required.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|<workload> Specific Rules|Allow Inbound **HTTPS (TCP 65503-65534)** from Service Tag `AzureLoadBalancer`|Inbound|<priority>|Allow|AzureLoadBalancer|*|*|65503-65534|

#### NSG <adbpublicXX-subnet>

> **Note:** below is the NSG for Public subnet for the Azure Databricks Network Solution in a custom VNet. Since multiple rules are [enforced by Azure Databricks using a Network Intent Policy](https://databricks.com/blog/2019/03/20/azure-databricks-bring-your-own-vnet.html), the rules in this NSG shouldn't be changed. Use the exact NSG below to add the ADB Network Solution to your VNet. This allows for secure, bidirectional communicaton with the Control Plane/WebApp.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|ADB Public specific|Allow Inbound **ALL** Databricks worker to worker traffic|Inbound|100|Allow|VirtualNetwork|VirtualNetwork|*|*|
|ADB Public specific|Allow inbound **SSH (TCP 22)** from Databricks Control Plane `AzureDatabricks`|Inbound|110|Allow|AzureDatabricks|VirtualNetwork|*|22|
|ADB Public specific|Allow Inbound **Worker Proxy (TCP 5557)** from Databricks Control Plane `AzureDatabricks`|Inbound|120|Allow|AzureDatabricks|VirtualNetwork|*|5557|
|Default VNet rules|Deny Inbound **ALL** other traffic|Inbound|1000|Deny|*|*|*|*|
|ADB Public specific|Allow Outbound **ALL** Databricks worker to worker traffic|Outbound|100|Allow|VirtualNetwork|VirtualNetwork|*|*|*|
|ADB Public specific|Allow Outbound **HTTPS (TCP 443)** Databricks worker traffic to the Databricks WebApp `AzureDatabricks`|Outbound|200|Allow|VirtualNetwork|AzureDatabricks|*|443|
|ADB Public specific|Allow Outbound **TCP 3306** Databricks worker traffic to AzureSQL|Outbound|210|Allow|VirtualNetwork|Sql|*|3306|
|ADB Public specific|Allow Outbound **HTTPS (TCP 443)** Databricks worker traffic to AzureStorage|Outbound|220|Allow|VirtualNetwork|Storage|*|443|
|ADB Public specific|Allow Outbound **EventHub (TCP 9093)** Databricks worker traffic to AzureEventHub|Outbound|230|Allow|VirtualNetwork|EventHub|*|9093|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space|Outbound|231|Allow|<Address Prefix>|AzureCloud|*|80,443|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` Public IP space |Outbound|232|Allow|<Address Prefix>|Internet|*|80,443|

#### NSG <adbprivateXX-subnet>

> **Note:** below is the Private subnet for the Azure Databricks Network Solution in a custom VNet. Since multiple rules are [enforced by Azure Databricks using a Network Intent Policy](https://databricks.com/blog/2019/03/20/azure-databricks-bring-your-own-vnet.html), the rules in this NSG shouldn't be changed. Use the exact NSG below to add the ADB Network Solution to your VNet. This allows for secure, bidirectional communicaton with the Control Plane/WebApp.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|ADB private specific|Allow Inbound **ALL** Databricks worker to worker traffic|Inbound|100|Allow|VirtualNetwork|VirtualNetwork|*|*|
|ADB private specific|Allow Inbound **SSH (TCP 22)** from Databricks Control Plane `AzureDatabricks`|Inbound|110|Allow|AzureDatabricks|VirtualNetwork|*|22|
|ADB private specific|Allow inbound **Worker Proxy (TCP 5557)** from Databricks Control Plane `AzureDatabricks`|Inbound|120|Allow|AzureDatabricks|VirtualNetwork|*|5557|
|Default VNet rules|Deny Inbound **ALL** Other traffic|Inbound|1000|Deny|*|*|*|*|
|ADB private specific|Allow Outbound **ALL** Databricks worker to worker traffic |Outbound|100|Allow|VirtualNetwork|VirtualNetwork|*|*|
|ADB private specific|Allow Outbound **HTTPS (TCP 443)** Databricks worker traffic to the Databricks WebApp `AzureDatabricks`|Outbound|200|Allow|VirtualNetwork|AzureDatabricks|*|443|
|ADB private specific|Allow outbound **TCP 3306** Databricks worker to AzureSQL|Outbound|210|Allow|VirtualNetwork|Sql|*|3306|
|ADB private specific|Allow outbound **HTTPS (TCP 443)** Databricks worker to AzureStorage|Outbound|220|Allow|VirtualNetwork|Storage|*|443|
|ADB private specific|Allow Outbound **EventHub (TCP 9093)** Databricks worker traffic to AzureEventHub|Outbound|230|Allow|VirtualNetwork|EventHub|*|9093|

#### NSG <appgwXX-subnet>
  **Application Gateway v3**
> **Note:** below is the default base rule set. If no inbound traffic from On-Prem is required, remove rule 200. If no outbound traffic to AzurePrivateInfraServices is required, remove rule 200.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|---|---|---|---|---|---|---|---|---|---|---|
|Default rules|Allow Inbound **ANY** IntraSubnet traffic between nodes in the appgwXX-subnet|Inbound|100|Allow|<Address Prefix>|<Address Prefix>|*|*|
|AppGW specific rules|Allow Inbound **HTTPS (TCP 65503-65534)** from Service Tag `AzureLoadBalancer`|Inbound|101|Allow|AzureLoadBalancer|<Address Prefix>|*|65503-65534|
|Default rules|Allow Inbound **HTTPS (TCP 443)** from Internal IP space `10.0.0.0/8`|Inbound|200|Allow|10.0.0.0/8|<Address Prefix>|*|443|
|AppGW specific rules|Allow Inbound **(TCP 65503-65534)** from Service Tag `Internet`|Inbound|300|Allow|Internet|<Address Prefix>|*|65503-65534|
|Default rules|Deny Inbound **ALL** other traffic|Inbound|1000|Deny|*|<Address Prefix>|*|*|
|Default rules|Allow Outbound **ALL** IntraSubnet traffic between nodes in the appgwXX-subnet|Outbound|100|Allow|<Address Prefix>|<Address Prefix>|*|*|
|AppGW specific rules|Allow outbound HTTPS (TCP 443) traffic from appgwXX-subnet to AzureBackendServices|Outbound|110|Allow|<Address Prefix>|AzureCloud|*|443|
|Default VNet rules|Allow Outbound **ALL** from appgwXX-subnet to AzurePrivateInfraServices|Outbound|200|Allow|<Address Prefix>|10.232.0.0/24, 10.232.1.0/24, 10.232.2.0/24, 10.232.19.0/24|*|*|
|AppGW specific rules|Deny Outbound **ALL** other traffic from associated subnets by the use of Service Tag `VirtualNetwork`|Outbound|1000|Deny|VirtualNetwork|*|*|*|

#### NSG <aksXX-subnet>

> **Note:** below NSG is the default rule pattern for the <aksXX-subnet>. The existing rules shouldn't be changed. However, inbound/outbound traffic from/to specific subnets in Azure Private can be added to the NSG rules, as long as the priority of the rule(s) have a higher priority than 200 (since rule 200 denies all other access from/to Azure Private). Add `<workload> Specific rules` as `Type`.

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|Default VNet rules|Allow Inbound **ALL** IntraSubnet traffic between nodes in the <aksXX-subnet>|Inbound|100|Allow|<Address prefix>|<Address prefix>|*|*|
|AKS specific rules|Deny Inbound **ANY** other access from Azure Private IP space except previously explicitly allowed rules|Inbound|200|Deny|10.232.0.0/16|<Address prefix>|*|*|
|AKS specific rules|Allow Inbound **HTTPS (TCP 443)** from ABN AMRO Internally|Inbound|201|Allow|10.0.0.0/8|<Address prefix>|*|443|
|AKS specific rules|Deny Inbound **SSH (TCP 22)** from ABN AMRO Internally|Inbound|202|Deny|10.0.0.0/8|<Address prefix>|*|22|
|AKS specific rules|Allow Inbound traffic from `AzureLoadBalancer` service tag for backend services to work|Inbound|203|Allow|AzureLoadBalancer|<Address prefix>|*|*|
|Default VNet rules|Deny Inbound **ALL** other traffic|Inbound|1000|Deny|*|*|*|*|
|Default VNet rules|Allow Outbound **ALL** IntraSubnet traffic between nodes in the <aksXX-subnet>|Outbound|100|Allow|<Address prefix>|<Address prefix>|*|*|
|Default VNet rules|Allow Outbound **ALL** from <aksXX-subnet> to AzurePrivateInfraServices|Outbound|101|Allow|<Address prefix>|10.232.0.0/24, 10.232.1.0/24, 10.232.2.0/24, 10.232.19.0/24|*|*|
|AKS specific rules|Deny Outbound **ALL** other access to Azure Private IP space except previously explicitly allowed rules|Outbound|200|Deny|<Address prefix>|10.232.0.0/16|*|*|
|AKS specific rules|Deny Outbound **ALL** other access to On-Premise Intranet IP space|Outbound|201|Deny|<Address prefix>|10.0.0.0/8|*|*|
|AKS specific rules|Allow Outbound **NTP (UDP 123)** traffic to `Internet` via Azure NSP|Outbound|202|Allow|<Address prefix>|*|*|123|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space|Outbound|203|Allow|10.232.83.0/26|AzureCloud|*|80,443|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` IP space|Outbound|204|Allow|10.232.83.0/26|Internet|*|80,443|

> **Note:** Flow Logs should be enabled/checked by default on every NSG.

- [X] Enable Flow Logs

#### NSG appserviceXX-subnet

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|Default VNet rules|Deny Inbound **ALL** traffic to appservice01-subnet|Inbound|100|Deny|*|<Address prefix>|*|*|
|Appservice VNet rules|Allow Outbound **ALL** IntraSubnet traffic between nodes in the appservice01-subnet|Outbound|100|Allow|<Address prefix>|<Address prefix>|*|*|
|Appservice VNet rules|Allow Outbound **ALL** from appservice01-subnet to AzurePrivateInfraServices|Outbound|110|Allow|<Address prefix>|10.232.0.0/24, 10.232.1.0/24, 10.232.2.0/24, 10.232.19.0/24|*|*|
|Appservice VNet rules|Deny Outbound **ALL** to Azure Private IP space except for previously explicitly defined rules with higher priority|Outbound|200|Deny|<Address prefix>|10.232.0.0/16|*|*|
|Appservice VNet rules|Deny Outbound **ALL** to Internal IP space|Outbound|210|Deny|<Address prefix>|10.0.0.0/8|*|*|
|Appservice VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space|Outbound|300|Allow|<Address prefix>|AzureCloud|*|80,443|
|Default VNet rules|Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` Public IP space|Outbound|310|Allow|<Address prefix>|Internet|*|80,443|

> **Note:** Flow Logs should be enabled/checked by default on every NSG.

- [X] Enable Flow Logs

#### NSG appgwXX-subnet
  **Application Gateway v4**

|Type|Name|Direction|Priority|Access|From address|To address|From port|To port|
|-|-|-|-|-|-|-|-|-|
|Default VNet rules|Allow Inbound **Any** IntraSubnet traffic between nodes in the appgw01-subnet|Inbound|100|Allow|<Address prefix>|<Address prefix>|*|*|
|AppGW specific|Allow inbound **Any** from `AzureLoadBalancer` backend to the appgw01-subnet|Inbound|110|Allow|AzureLoadBalancer|<Address prefix>|*|*|
|AppGW specific|Allow inbound **HTTPS (TCP 443)** traffic from Akamai SiteShield map to the appgw01-subnet|Inbound|120|Allow|**<Address prefixes> from Akamai**|<Address prefix>|*|443|
|AppGW specific|Allow inbound **(TCP 65200-65535)** from `GatewayManager` service tag|Inbound|130|Allow|GatewayManager|*|*|65200-65535|
|Default VNet rules|Allow outbound **Any** IntraSubnet traffic between nodes in the appgw01-subnet|Outbound|100|Allow|<Address prefix>|<Address prefix>|*|*|
|AppGW specific|Allow outbound **HTTPS (TCP 443)** traffic from appgw01-subnet to AzureBackendServices|Outbound|110|Allow|<Address prefix>|AzureCloud|*|443|
|AppGW specific|Allow outbound **DNS (TCP 53)** from appgw01-subnet to DNS servers|Outbound|120|Allow|<Address prefix>|10.232.2.0/24|*|53|
|AppGW specific|Allow outbound **Any** from `AzureLoadBalancer`|Outbound|130|Allow|AzureLoadBalancer|*|*|*|

> **Note:** Flow Logs should be enabled/checked by default on every NSG.

- [X] Enable Flow Logs

## Zone Interconnect Firewall Rules (Palo Alto)

> **Note:** it is the customer DevOps team responsibility to request Zone Interconnect Firewall Rules. Below is some guidance on what to mention.

- Relation with Inbound/Outbound NSG rules
- Currently no traffic flows known which require changes

## Azure Network Secure Perimeter

|Type|Name|Direction|Access|From address|To address|From port|To port|
|---|---|---|---|---|---|---|---|---|---|