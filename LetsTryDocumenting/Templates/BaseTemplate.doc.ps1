#region Create README
Document 'README' {

    Title "Virtual Network $($InputObject.VirtualNetworkName)"
    '[[_TOC_]]'

    Section "Version Context" {
        Section "Environment Details" {
            "- Subscription:"
                ('  - [X] {0}' -f $($InputObject.Environment.SubscriptionName))
            "- Virtual Network Name: $($InputObject.VirtualNetworkName)"
            "- Location: $($InputObject.Environment.Location)"
            "- Allowed Locations: $($InputObject.Environment.AllowedLocation)"
            "- Tags: $($InputObject.Environment.Tags)"
        }
    }

    Section "Virtual Network" {
        ('- Address Space: {0}' -f $([string]::Join(',', $($InputObject.Subnet.AddressSpace|ForEach-Object {"``$_``"}))))
        ('- [{0}] Azure DNS' -f ($($InputObject.DNS) -eq 'AzureDNS'))

        Section "Peering" {
            '- Default HUB-Spoke deployment model'
            ('- [{0}] Hub/Spoke'-f ($($InputObject.Peering) -eq 'Hub/Spoke'))
            ('- [{0}] Spoke/Spoke'-f ($($InputObject.Peering) -eq 'Spoke/Spoke'))
            '   - [ ] Peering to `<Peer VNet name>` in `Peer VNet Resource Group`, `Peer VNet Subscription Id`'
        }

        Section 'Subnet' {
            $InputObject.Subnet | Table -Property @{Name='Subnet name'; Expression={$_.SubnetName}}, @{Name='Address Space'; Expression ={$_.AddressSpace}},  @{Name='Service EndPoint'; Expression={($_.ServiceEndpoint) -join '<br />' }}
        }

        $InputObject.RouteTableSection

        $InputObject.NsgSection
    }
}