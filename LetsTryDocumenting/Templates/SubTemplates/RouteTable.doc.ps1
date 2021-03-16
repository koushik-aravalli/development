Document 'README' {
    Section 'Route Tables' {
        Foreach ($subnet in $($InputObject.Subnet)) {
            ('  - [ ] {0}' -f $subnet.SubnetName)
        }

        Foreach ($subnet in $($InputObject.Subnet)) {
            Section ('RT {0}' -f $($subnet.SubnetName)) {
                [PSCustomObject]@{
                    'Name' = 'Default'
                    'Address Prefix' = '0.0.0.0/0'
                    'Next Hop Type' = 'Internet'
                    'Next Hop IP Address' = ''
                } | Table
            }
        }
    }
}