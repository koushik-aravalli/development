#region Create README
Document 'README' {

    Title "Virtual Network $($InputObject.VirtualNetworkName)"
    '[[_TOC_]]'

    Section "Version Context" {
        Section "Environment Details" {
            "- Subscription:"
                ('  - [X] ``{0}``' -f $($InputObject.Environment.SubscriptionName))
            "- Virtual Network Name: ``$($InputObject.VirtualNetworkName)``"
            "- Location: ``$($InputObject.Environment.Location)``"
        }
        Section "Tags" {
            $InputObject.Environment.Tags | Table -Property @{Name='Name'; Expression={$_.Keys}},@{Name='Value'; Expression={$_.Values}}
        }
    }

    Section "Virtual Network" {
        ('- Address Space: {0}' -f $([string]::Join(',', $($InputObject.Subnet.AddressSpace|ForEach-Object {"``$_``"}))))
        ('- [{0}] Azure DNS' -f ($($InputObject.DNS) -eq 'AzureDNS'))

        Section "Peering" {
            If ($InputObject.Subnet.SubnetName -contains 'GatewaySubnet') {
                '- VNET Type : ``{0}``' -f 'HUB'
            }
            Else{
                '- VNET Type : ``{0}``' -f 'Spoke'
            }
            Foreach ($peering in $InputObject.Peering) {
                '   - [X] Peering to VNET ``{0}`` in ResourceGroup ``{1}``' -f $peering.split('/')[-1],$peering.split('/')[4]
            }
        }

        Section 'Subnet' {
            $InputObject.Subnet | Table -Property @{Name='Subnet name'; Expression={$_.SubnetName}}, @{Name='Address Space'; Expression ={$_.AddressSpace}},  @{Name='Service EndPoint'; Expression={($_.ServiceEndpoint) -join '<br />' }}
        }

        $InputObject.RouteTableSection

        $InputObject.NsgSection

        Section 'Private DNS Zone Links' {
            $InputObject.PrivateDNS | Table -Property @{Name='Private DNS'; Expression={$_.Split('/')[-1]}},@{Name='Resource Group'; Expression={$_.Split('/')[4]}}
        }
        
    }
}