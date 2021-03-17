# Network Solution for vnet-hub

[[_TOC_]]

## General information

- Subscription:

  - [X] ``Visual Studio Professional with MSDN``

- Virtual Network Name: `vnet-hub`

- Location: `westeurope`

### Tags

|Name|Value|
|----|-----|
|

## Virtual Network

- Address Space: `10.0.3.0/26`,`10.0.2.0/27`,`10.0.1.0/29`

- [X] Azure DNS

### Peering

- VNET Type : ``HUB``

   - [X] Peering to VNET ``vnet-spoke-one`` in ResourceGroup ``hub-spoke``

   - [X] Peering to VNET ``vnet-spoke-two`` in ResourceGroup ``hub-spoke``

### Subnet

|Subnet name|Address Space|Service EndPoint|
|-----------|-------------|----------------|
|AzureFirewallSubnet|10.0.3.0/26||
|GatewaySubnet|10.0.2.0/27||
|AzureBastionSubnet|10.0.1.0/29||

### Route Tables

  - [ ] AzureFirewallSubnet

  - [ ] GatewaySubnet

  - [ ] AzureBastionSubnet

#### RT AzureFirewallSubnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||

#### RT GatewaySubnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||

#### RT AzureBastionSubnet

|Name|Address Prefix|Next Hop Type|Next Hop IP Address|
|----|--------------|-------------|-------------------|
|Default|0.0.0.0/0|Internet||


### Network Security Group

#### NSG AzureBastionSubnet

|Name|Direction|Priority|Access|From address|To address|From port|To port|
|----|---------|--------|------|------------|----------|---------|-------|
|AllowVnetInBound|Inbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowAzureLoadBalancerInBound|Inbound|65001|Allow|AzureLoadBalancer|*|*|*|
|DenyAllInBound|Inbound|65500|Deny|*|*|*|*|
|AllowVnetOutBound|Outbound|65000|Allow|VirtualNetwork|VirtualNetwork|*|*|
|AllowInternetOutBound|Outbound|65001|Allow|*|Internet|*|*|
|DenyAllOutBound|Outbound|65500|Deny|*|*|*|*|
|bastion-in-allow|Inbound|100|Allow|Internet|*|*|*|
|bastion-control-in-allow|Inbound|120|Allow|GatewayManager|*|*|*|
|bastion-in-host|Inbound|130|Allow|VirtualNetwork|VirtualNetwork|*|*|
|bastion-vnet-out-allow|Outbound|100|Allow|*|VirtualNetwork|*|*|
|bastion-azure-out-allow|Outbound|120|Allow|*|AzureCloud|*|*|
|bastion-out-host|Outbound|130|Allow|VirtualNetwork|VirtualNetwork|*|*|
|bastion-out-deny|Outbound|1000|Deny|*|*|*|*|

