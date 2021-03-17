# Network Solution for vnet-spoke-one

[[_TOC_]]

## General information

- Subscription:

  - [X] ``Visual Studio Professional with MSDN``

- Virtual Network Name: `vnet-spoke-one`

- Location: `westeurope`

### Tags

|Name|Value|
|----|-----|
|

## Virtual Network

- Address Space: `10.100.0.0/16`

- [X] Azure DNS

### Peering

- VNET Type : ``Spoke``

   - [X] Peering to VNET ``vnet-hub`` in ResourceGroup ``hub-spoke``

### Subnet

|Subnet name|Address Space|Service EndPoint|
|-----------|-------------|----------------|
|snet-spoke-resources|10.100.0.0/16||

### Route Tables

  - [ ] snet-spoke-resources

#### RT snet-spoke-resources

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||


### Network Security Group

#### NSG snet-spoke-resources

|Name|Direction|Priority|Access|From address|To address|From port|To port|
|----|---------|--------|------|------------|----------|---------|-------|
|AllowVnetInBound|Inbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowAzureLoadBalancerInBound|Inbound|65001|Allow|AzureLoadBalancer|*|*|*|
|DenyAllInBound|Inbound|65500|Deny|*|*|*|*|
|AllowVnetOutBound|Outbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowInternetOutBound|Outbound|65001|Allow|*|Internet|*|*|
|DenyAllOutBound|Outbound|65500|Deny|*|*|*|*|
|bastion-in-vnet|Inbound|100|Allow|10.0.1.0/29|*|*|*|
|DenyAllInBound|Inbound|1000|Deny|*|*|*|*|

