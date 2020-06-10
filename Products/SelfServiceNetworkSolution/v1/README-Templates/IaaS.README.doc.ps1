#region Create README
Document 'README' {

    Title "Virtual Network $($InputObject.VirtualNetworkName)"

    '[[_TOC_]]'

    Section "Version Context" {

        "- Customer Workload: $($InputObject.Environment.AppName)"
        "- Customer Contact: $($InputObject.Environment.ContactMail)"
        "- Solution Version: $($InputObject.SolutionVersion)"

        Section "Environment Details" {

            "- Subscription:"
                ('  - [X] {0}' -f $($InputObject.Environment.SubscriptionName))
            "- Virtual Network Name: $($InputObject.VirtualNetworkName)"
            "- Environment"
                ('  - [{0}] Engineering' -f ($($InputObject.Environment.EnvironmentType) -eq 'Engineering') ) 
                ('  - [{0}] Development' -f ($($InputObject.Environment.EnvironmentType) -eq 'Development') ) 
                ('  - [{0}] Test' -f ($($InputObject.Environment.EnvironmentType) -eq 'Test') ) 
                ('  - [{0}] Acceptance' -f ($($InputObject.Environment.EnvironmentType) -eq 'Acceptance') ) 
                ('  - [{0}] Production' -f ($($InputObject.Environment.EnvironmentType) -eq 'Production') ) 
            "- ServiceName: $($InputObject.Environment.ServiceName)"
            "- Location: $($InputObject.Environment.Location)"
            "- Allowed Locations: $($InputObject.Environment.AllowedLocation)"
            "- Business Application CI: $($InputObject.Environment.BusinessApplicationCI)"
            "- Billing code: $($InputObject.Environment.BillingCode)"
            "- Provider: $($InputObject.Environment.Provider)"
            "- AppName:  $($InputObject.Environment.AppName)"
            "- CIA: $($InputObject.Environment.CIA)"
            "- ContactMail: $($InputObject.Environment.ContactMail)"
            "- ContactPhone: $($InputObject.Environment.ContactPhone)"
        }
    }

    Section "Solution Specifics" {
        
        Section "Design Decisions" {
            ''
        }
    }

    Section "Virtual Network" {
        ('- Address Space: `{0}`' -f ('{0}' -f $($InputObject.Subnet.AddressSpace)) )
        ('- [{0}] Azure DNS' -f ($($InputObject.DNS) -eq 'AzureDNS'))
        ('- [{0}] Azure ADDS DNS (`10.232.2.4` and `10.232.2.5`)' -f ($($InputObject.DNS) -eq 'AzureADDSDNS') )
        ('- [{0}] On-prem Infoblox (`10.124.237.66` and `10.124.226.228`)' -f ($($InputObject.DNS) -eq 'On-PremInfoBlox') )

        $InputObject.Subnet | Table -Property @{'Name'='Subnet name'; E={ $_.SubnetName}}  , @{'Name'='Address Space'; E={$_.AddressSpace}} ,  @{'Name'='Service EndPoint'; E={($_.ServiceEndpoint) -join '<br />' }}     
        
        Section "Peering" {

            '- Default HUB-Spoke deployment model (HUB in Management, Spoke in selected WL subnets (e.g. VDC2S))'
            ('- [{0}] Hub/Spoke'-f ($($InputObject.Peering) -eq 'Hub/Spoke'))
            ('- [{0}] Spoke/Spoke'-f ($($InputObject.Peering) -eq 'Spoke/Spoke'))
            '   - [ ] Peering to `nsp02-e-vnet` in `nsp02-vnets-e-rg`, `0a1e54a3-58b3-40f8-82bd-efd7844068a5`'
            '   - [ ] Peering to `infra01-vnet` in `infra-vnets-p-rg`, `b658ffad-30c7-4be6-881c-e3dc1f6520af`'
            '   - [ ] Peering to `<Peer VNet name>` in `Peer VNet Resource Group`, `Peer VNet Subscription Id`'
        }

        Section 'Subnet' {

            '' # empty seecion
            

        }
        Section 'Delegation' {
            ('- [X] Resource Group: {0} `{1}`: `Reader`'-f $($InputObject.Delegation.ResourceGroup.Name), $($InputObject.Delegation.ResourceGroup.ObjectId))
            ('- [X] Subnet Join for {0}: {1} `{2}`: `CBSP Azure Virtual Network Subnet Join [Production]`' -f $($InputObject.Delegation.SubnetJoin.SubnetName), $($InputObject.Delegation.SubnetJoin.SPNName), $($InputObject.Delegation.SubnetJoin.ObjectId) )
        }
        Section 'Route Tables' {
            '- [ ] M365-Common ID 56: 10.232.1.68'
            ('  - [ ] {0}' -f $($InputObject.Subnet.SubnetName)) 
       
            'List of [M365-Common ID 56 Required](https://docs.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges#microsoft-365-common-and-office-online) routes.'

                Section ('RT {0}' -f $($InputObject.Subnet.SubnetName))  {
                    
                    If ($InputObject.Environment.EnvironmentType -eq 'Engineering', 'Development' -or 'Test') {
                        [PSCustomObject]@{
                            'Name' = 'Default-Route-NSP'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.110.196'
                        } | Table
                    }
                    ElseIf ($InputObject.Environment.EnvironmentType -eq 'Acceptance' -or 'Production') {
                        [PSCustomObject]@{
                            'Name' = 'Default-Route-NSP'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.1.4'
                        } | Table
                    }
                }
        }
        Section 'Network Security Group' {
            
            Section ('NSG {0}' -f $($InputObject.Subnet.SubnetName))  {
                $NSGs = [PSCustomObject]@(                  
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = ( 'Allow Inbound **ALL** IntraSubnet traffic between nodes in the {0}' -f $($InputObject.Subnet.SubnetName))
                    'Direction' = 'Inbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Deny Inbound **ALL** from Azure Private IP space except for previously expilicitly defined rules with higher priority'
                    'Direction' = 'Inbound'
                    'Priority' = '200'
                    'Access' = 'Deny'
                    'From address' = '10.232.0.0/16'
                    'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Inbound **HTTPS (TCP 443)** from ABN AMRO internally'
                    'Direction' = 'Inbound'
                    'Priority' = '201'
                    'Access' = 'Allow'
                    'From address' = '10.0.0.0/8'
                    'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'From port' = '*'
                    'To port' = '443'
                },
                @{
                    'Type' = 'Default VNet rule'
                    'Name' = 'Deny Inbound **ALL** other traffic'
                    'Direction' = 'Inbound'
                    'Priority' = '1000'
                    'Access' = 'Deny'
                    'From address' = '*'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **ALL** IntraSubnet traffic between nodes in the dev01-subnet'
                    'Direction' = 'Outbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **ALL** from dev01-subnet to AzurePrivateInfraServices'
                    'Direction' = 'Outbound'
                    'Priority' = '101'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = '10.232.0.0/24, 10.232.1.0/24, 10.232.2.0/24, 10.232.19.0/24'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Deny Outbound **ALL** to Azure Private IP space except for previously explicitly defined rules with higher priority'
                    'Direction' = 'Outbound'
                    'Priority' = '102'
                    'Access' = 'Deny'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = '10.232.0.0/16'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **TCP 8080** to On-Prem Proxy LoadBalancer IP'
                    'Direction' = 'Outbound'
                    'Priority' = '103'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = '10.120.118.50/32'
                    'From port' = '*'
                    'To port' = '8080'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **ALL** to Internal IP space'
                    'Direction' = 'Outbound'
                    'Priority' = '104'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = '10.0.0.0/8'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space'
                    'Direction' = 'Outbound'
                    'Priority' = '204'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = 'AzureCloud'
                    'From port' = '*'
                    'To port' = '80,443'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` Public IP space'
                    'Direction' = 'Outbound'
                    'Priority' = '205'
                    'Access' = 'Allow'
                    'From address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                    'To address' = 'Internet'
                    'From port' = '*'
                    'To port' = '80,443'
                })

                #region add LoadBalancer NSG if LoadBalancer is configured
                #|<workload> Specific Rules|Allow Inbound **HTTPS (TCP 65503-65534)** from Service Tag `AzureLoadBalancer`|Inbound|300|Allow|AzureLoadBalancer|*|*|65503-65534|
                If ($InputObject.LoadBalancer -eq 'true')
                {
                    $LoadBalancerNSG = @{
                        'Type' = ('{0} Specific Rules' -f $($InputObject.Environment.AppName))
                        'Name' = 'Allow Inbound **HTTPS (TCP 65503-65534)** from Service Tag `AzureLoadBalancer`'
                        'Direction' = 'Inbound'
                        'Priority' = '300'
                        'Access' = 'Allow'
                        'From address' = 'AzureLoadBalancer'
                        'To address' = '*'
                        'From port' = '*'
                        'To port' = '65503-65534'
                    }
                    $NSGs += $LoadBalancerNSG
                }
                #endregion

                #region add RDP & SSH NSG rules if the option to disable JIT/PIM is configured
                If ($InputObject.DisableJITPIM -eq 'true')
                {
                    $RDPandSSHNSGs = @{
                        'Type' = 'Default VNet rules'
                        'Name' = 'Allow Inbound **SSH (TCP 22)** from ABN AMRO internally'
                        'Direction' = 'Inbound'
                        'Priority' = '202'
                        'Access' = 'Allow'
                        'From address' = '10.0.0.0/8'
                        'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                        'From port' = '*'
                        'To port' = '22'
                    },
                    @{
                        'Type' = 'Default VNet rules'
                        'Name' = 'Allow Inbound **RDP (TCP 3389)** from ABN AMRO internally'
                        'Direction' = 'Inbound'
                        'Priority' = '203'
                        'Access' = 'Allow'
                        'From address' = '10.0.0.0/8'
                        'To address' = ('{0}' -f $($InputObject.Subnet.AddressSpace))
                        'From port' = '*'
                        'To port' = '3389'
                    }
    
                    $NSGs += $RDPandSSHNSGs
                }
                #endregion

                $NSGs | Table -Property Type, Name, Direction, Priority, Access, 'From address', 'To address', 'From port', 'To port'
                '- [X] Enable Flow Logs'
            }
        }
    }
    Section "Zone Interconnect Firewall Rules (Palo Alto)" {
        '- Relation with Inbound/Outbound NSG rules'
        '- Currently no traffic flows known which require changes'
    }
    Section "Azure Network Secure Perimeter" {
        [PSCustomObject]@{
                'Type' = ''
                'Name' = ''
                'Direction' = ''
                'Access' = ''
                'From address' = ''
                'To address' = ''
                'From port' = ''
                'To port' = ''
            } | Table -Property Type, Name, Direction, Access, 'From address', 'To address', 'From port', 'To port'
    }         
}
#endregion