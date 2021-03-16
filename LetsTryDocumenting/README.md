# Virtual Network lts-vnet

[[_TOC_]]

## Version Context

### Environment Details

- Subscription:

  - [X] ``Visual Studio Professional with MSDN``

- Virtual Network Name: `lts-vnet`

- Location: `northeurope`

- Allowed Locations: `westeurope, northeurope`

- Tags: ``

## Virtual Network

- Address Space: `10.0.2.0/28`,`10.0.0.0/24`,`10.0.1.0/24`

- [ ] Azure DNS

### Peering

- VNET Type : ``HUB``

   - [X] Peering to VNET ``spoke1`` in ResourceGroup ``iaas-workload``

### Subnet

|Subnet name|Address Space|Service EndPoint|
|-----------|-------------|----------------|
|GatewaySubnet|10.0.2.0/28||
|paas-subnet|10.0.0.0/24||
|iaasSubnet|10.0.1.0/24||

### Route Tables

  - [ ] GatewaySubnet

  - [ ] paas-subnet

  - [ ] iaasSubnet

#### RT GatewaySubnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||

#### RT paas-subnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||

#### RT iaasSubnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||


### Network Security Group

#### NSG paas-subnet

|Name|Direction|Priority|Access|From address|To address|From port|To port|
|----|---------|--------|------|------------|----------|---------|-------|
|AllowVnetInBound|Inbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowAzureLoadBalancerInBound|Inbound|65001|Allow|AzureLoadBalancer|*|*|*|
|DenyAllInBound|Inbound|65500|Deny|*|*|*|*|
|AllowVnetOutBound|Outbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowInternetOutBound|Outbound|65001|Allow|*|Internet|*|*|
|DenyAllOutBound|Outbound|65500|Deny|*|*|*|*|

#### NSG iaasSubnet

|Name|Direction|Priority|Access|From address|To address|From port|To port|
|----|---------|--------|------|------------|----------|---------|-------|
|AllowVnetInBound|Inbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowAzureLoadBalancerInBound|Inbound|65001|Allow|AzureLoadBalancer|*|*|*|
|DenyAllInBound|Inbound|65500|Deny|*|*|*|*|
|AllowVnetOutBound|Outbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowInternetOutBound|Outbound|65001|Allow|*|Internet|*|*|
|DenyAllOutBound|Outbound|65500|Deny|*|*|*|*|


### Private DNS Zone Links

|Private DNS|Resource Group|
|-----------|--------------|
|privatelink.blob.core.windows.net|lts-vnet-ne|
