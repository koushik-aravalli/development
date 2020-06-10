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
        ('- Address Space: `{0}, {1}`' -f $($InputObject.Subnet.AddressSpace[0]), $($InputObject.Subnet.AddressSpace[1]) )
        ('- [{0}] Azure DNS' -f ($($InputObject.DNS) -eq 'AzureDNS'))
        ('- [{0}] Azure ADDS DNS (`10.232.2.4` and `10.232.2.5`)' -f ($($InputObject.DNS) -eq 'AzureADDSDNS') )
        ('- [{0}] On-prem Infoblox (`10.124.237.66` and `10.124.226.228`)' -f ($($InputObject.DNS) -eq 'On-PremInfoBlox') )

        $InputObject.Subnet | Table -Property @{'Name'='Subnet name'; E={ $_.SubnetName}}  , @{'Name'='Address Space'; E={$_.AddressSpace}} ,  @{'Name'='Service EndPoint'; E={($_.ServiceEndpoint) -join '<br />' }}     
        
        Section "Peering" {

            '- Default HUB-Spoke deployment model (HUB in Management, Spoke in selected WL subnets (e.g. VDC2S))'
            ('- [{0}] Hub/Spoke'-f ($($InputObject.Peering) -eq 'Hub/Spoke'))
            ('- [{0}] Spoke/Spoke'-f ($($InputObject.Peering) -eq 'Spoke/Spoke'))
            '  - [ ] Peering to `nsp02-e-vnet` in `nsp02-vnets-e-rg`, `0a1e54a3-58b3-40f8-82bd-efd7844068a5`'
            '  - [ ] Peering to `infra01-vnet` in `infra-vnets-p-rg`, `b658ffad-30c7-4be6-881c-e3dc1f6520af`'
            '  - [ ] Peering to `<Peer VNet name>` in `Peer VNet Resource Group`, `Peer VNet Subscription Id`'
        }

        Section 'Subnet' {

            '' # empty seecion
        }
        Section 'Delegation' {
            ('- [X] Resource Group: {0} `{1}`: `Reader`'-f $($InputObject.Delegation.ResourceGroup.Name), $($InputObject.Delegation.ResourceGroup.ObjectId))
            ('- [X] Subnet Join for {0}: {1} `{2}`: `CBSP Azure Virtual Network Subnet Join [Production]`' -f $($InputObject.Delegation.SubnetJoin[0].SubnetName), $($InputObject.Delegation.SubnetJoin[0].SPNName), $($InputObject.Delegation.SubnetJoin[0].ObjectId) )
            ('- [X] Subnet Join for {0}: {1} `{2}`: `CBSP Azure Virtual Network Subnet Join [Production]`' -f $($InputObject.Delegation.SubnetJoin[1].SubnetName), $($InputObject.Delegation.SubnetJoin[1].SPNName), $($InputObject.Delegation.SubnetJoin[1].ObjectId) )
        }
        Section 'Route Tables' {
            '- [ ] M365-Common ID 56: 10.232.1.68'
            ('  - [ ] {0}' -f $($InputObject.Subnet.SubnetName[0]))
            ('  - [ ] {0}' -f $($InputObject.Subnet.SubnetName[1])) 
       
            'List of [M365-Common ID 56 Required](https://docs.microsoft.com/en-us/office365/enterprise/urls-and-ip-address-ranges#microsoft-365-common-and-office-online) routes.'

                Section ('RT {0}' -f $($InputObject.Subnet.SubnetName | Where-Object -FilterScript {$_.StartsWith('adbprivate')})) {
                    
                    If ($InputObject.Environment.EnvironmentType -eq 'Engineering', 'Development' -or 'Test') {
                        @([PSCustomObject]@{
                            'Name' = 'Route-to-DNS-DC1'
                            'Address Prefix' = '10.232.2.4/32'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.10.132'
                        },
                        [PSCustomObject]@{
                            'Name' = 'Route-to-DNS-DC2'
                            'Address Prefix' = '10.232.2.5/32'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.10.132'
                        },
                        [PSCustomObject]@{
                            'Name' = 'Default-Null-Route'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'None'
                            'Next Hop IP Address' = ''
                        }) | Table
                    }
                    ElseIf ($InputObject.Environment.EnvironmentType -eq 'Acceptance' -or 'Production') {
                        @([PSCustomObject]@{
                            'Name' = 'Route-to-DNS-DC1'
                            'Address Prefix' = '10.232.2.4/32'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.10.4'
                        },
                        [PSCustomObject]@{
                            'Name' = 'Route-to-DNS-DC2'
                            'Address Prefix' = '10.232.2.5/32'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.10.4'
                        },
                        [PSCustomObject]@{
                            'Name' = 'Default-Null-Route'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'None'
                            'Next Hop IP Address' = ''
                        }) | Table
                    }

                }

                Section ('RT {0}' -f $($InputObject.Subnet.SubnetName | Where-Object -FilterScript {$_.StartsWith('adbpublic')})) {
                    
                    If ($InputObject.Environment.EnvironmentType -eq 'Engineering') {
                        @([PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-Webapp'
                            'Address Prefix' = '52.232.19.246/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-NAT'
                            'Address Prefix' = '23.100.0.135/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Default-Route-NSP'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.110.68'
                        }) | Table
                    }
                    ElseIf ($InputObject.Environment.EnvironmentType -eq 'Development' -or 'Test') {
                        @([PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-Webapp'
                            'Address Prefix' = '52.232.19.246/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-NAT'
                            'Address Prefix' = '23.100.0.135/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Default-Route-NSP'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.110.196'
                        }) | Table
                    }
                    ElseIf ($InputObject.Environment.EnvironmentType -eq 'Acceptance' -or 'Production') {
                        @([PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-Webapp'
                            'Address Prefix' = '52.232.19.246/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Databricks-Control-Plane-NAT'
                            'Address Prefix' = '23.100.0.135/32'
                            'Next Hop Type' = 'Internet'
                            'Next Hop IP Address' = ''
                        },
                        [PSCustomObject]@{
                            'Name' = 'Default-Route-NSP'
                            'Address Prefix' = '0.0.0.0/0'
                            'Next Hop Type' = 'VirtualAppliance'
                            'Next Hop IP Address' = '10.232.1.4'
                        }) | Table
                    }
                }
        }
        Section 'Network Security Group' {
            
            Section ('NSG {0}' -f $($InputObject.Subnet.SubnetName | Where-Object -FilterScript {$_.StartsWith('adbprivate')}))  {
                $PrivateNSG = [PSCustomObject]@(                  
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow Inbound **ALL** Databricks worker to worker traffic'
                    'Direction' = 'Inbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow Inbound **SSH (TCP 22)** from Databricks Control Plane `AzureDatabricks`'
                    'Direction' = 'Inbound'
                    'Priority' = '110'
                    'Access' = 'Allow'
                    'From address' = 'AzureDatabricks'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '22'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow inbound **Worker Proxy (TCP 5557)** from Databricks Control Plane `AzureDatabricks`'
                    'Direction' = 'Inbound'
                    'Priority' = '120'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '5557'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Deny Inbound **ALL** Other traffic'
                    'Direction' = 'Inbound'
                    'Priority' = '1000'
                    'Access' = 'Deny'
                    'From address' = '*'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow Outbound **ALL** Databricks worker to worker traffic'
                    'Direction' = 'Outbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow Outbound **HTTPS (TCP 443)** Databricks worker traffic to the Databricks WebApp `AzureDatabricks`'
                    'Direction' = 'Outbound'
                    'Priority' = '200'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'AzureDatabricks'
                    'From port' = '*'
                    'To port' = '443'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow outbound **TCP 3306** Databricks worker to AzureSQL'
                    'Direction' = 'Outbound'
                    'Priority' = '210'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'Sql'
                    'From port' = '*'
                    'To port' = '3306'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow outbound **HTTPS (TCP 443)** Databricks worker to AzureStorage'
                    'Direction' = 'Outbound'
                    'Priority' = '220'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'Storage'
                    'From port' = '*'
                    'To port' = '443'
                },
                @{
                    'Type' = 'ADB private specific'
                    'Name' = 'Allow Outbound **EventHub (TCP 9093)** Databricks worker traffic to AzureEventHub'
                    'Direction' = 'Outbound'
                    'Priority' = '230'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'EventHub'
                    'From port' = '*'
                    'To port' = '9093'
                })

                $PrivateNSG | Table -Property Type, Name, Direction, Priority, Access, 'From address', 'To address', 'From port', 'To port'
                '- [X] Enable Flow Logs'
            }

            Section ('NSG {0}' -f $($InputObject.Subnet.SubnetName | Where-Object -FilterScript {$_.StartsWith('adbpublic')}))  {
                $PublicNSG = [PSCustomObject]@(                  
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow Inbound **ALL** Databricks worker to worker traffic'
                    'Direction' = 'Inbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow Inbound **SSH (TCP 22)** from Databricks Control Plane `AzureDatabricks`'
                    'Direction' = 'Inbound'
                    'Priority' = '110'
                    'Access' = 'Allow'
                    'From address' = 'AzureDatabricks'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '22'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow inbound **Worker Proxy (TCP 5557)** from Databricks Control Plane `AzureDatabricks`'
                    'Direction' = 'Inbound'
                    'Priority' = '120'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '5557'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Deny Inbound **ALL** Other traffic'
                    'Direction' = 'Inbound'
                    'Priority' = '1000'
                    'Access' = 'Deny'
                    'From address' = '*'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow Outbound **ALL** Databricks worker to worker traffic'
                    'Direction' = 'Outbound'
                    'Priority' = '100'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'VirtualNetwork'
                    'From port' = '*'
                    'To port' = '*'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow Outbound **HTTPS (TCP 443)** Databricks worker traffic to the Databricks WebApp `AzureDatabricks`'
                    'Direction' = 'Outbound'
                    'Priority' = '200'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'AzureDatabricks'
                    'From port' = '*'
                    'To port' = '443'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow outbound **TCP 3306** Databricks worker to AzureSQL'
                    'Direction' = 'Outbound'
                    'Priority' = '210'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'Sql'
                    'From port' = '*'
                    'To port' = '3306'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow outbound **HTTPS (TCP 443)** Databricks worker to AzureStorage'
                    'Direction' = 'Outbound'
                    'Priority' = '220'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'Storage'
                    'From port' = '*'
                    'To port' = '443'
                },
                @{
                    'Type' = 'ADB Public specific'
                    'Name' = 'Allow Outbound **EventHub (TCP 9093)** Databricks worker traffic to AzureEventHub'
                    'Direction' = 'Outbound'
                    'Priority' = '230'
                    'Access' = 'Allow'
                    'From address' = 'VirtualNetwork'
                    'To address' = 'EventHub'
                    'From port' = '*'
                    'To port' = '9093'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `AzurePublic` IP space'
                    'Direction' = 'Outbound'
                    'Priority' = '231'
                    'Access' = 'Allow'
                    'From address' = 'AzureCloud'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '80, 443'
                },
                @{
                    'Type' = 'Default VNet rules'
                    'Name' = 'Allow Outbound **HTTP+S (TCP 80, 443)** proxied or routed to `Internet` IP space'
                    'Direction' = 'Outbound'
                    'Priority' = '232'
                    'Access' = 'Allow'
                    'From address' = 'Internet'
                    'To address' = '*'
                    'From port' = '*'
                    'To port' = '80, 443'
                })

                $PublicNSG | Table -Property Type, Name, Direction, Priority, Access, 'From address', 'To address', 'From port', 'To port'
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