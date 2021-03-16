Document 'README' {
    Section 'Network Security Group' {
        Foreach ($subnet in $($InputObject.Subnet)) {
            Section ('NSG {0}' -f $($subnet.SubnetName)) {
                $NSGs = [System.Collections.ArrayList]@()
                Foreach ($securityRule in $subnet.Nsg.SecurityRules) {
                    $rule = [PSCustomObject]@{
                        'Name'         = $securityRule.Name
                        'Direction'    = $securityRule.Direction
                        'Priority'     = $securityRule.Priority
                        'Access'       = $securityRule.Access
                        'From address' = $securityRule.'From address' -join ','
                        'To address'   = $securityRule.'To address' -join ','
                        'From port'    = $securityRule.'From port' -join ','
                        'To port'      = $securityRule.'From port' -join ','
                    }
                    $NSGs.Add($rule) | out-null
                }

                $NSGs | Table -Property Name, Direction, Priority, Access, 'From address', 'To address', 'From port', 'To port'
            }
        }
    }
}