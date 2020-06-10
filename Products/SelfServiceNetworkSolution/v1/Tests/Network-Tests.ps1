<#

.EXAMPLE
    Invoke-Pester -Script @{ "Path" = "..\Tests\Network-Tests.ps1"; Parameters = @{ "ParameterPath" = ""; Files = $null} }

#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]

[CmdLetBinding()]
Param (
    [String] $ParameterPath,
    [String[]] $Files = @()
)

Describe "Json parameter validation" {
    BeforeAll {
        $DebugPreference = "Continue"
    }

    AfterAll {
        $DebugPreference = "SilentlyContinue"
    }

    $ParameterPath | Out-Default
    $testCases = @()
    If ($Files.Count -gt 0) {
        $Files | Where-Object -FilterScript { $_.ToLower().EndsWith(".json") } | ForEach-Object { $testCases += @{ "File" = $_ } }
    }
    Else {
        $Files = [System.IO.Directory]::GetFiles($ParameterPath, "*.json", [System.IO.SearchOption]::AllDirectories)
        $Files.GetEnumerator() | ForEach-Object { $testCases += @{ File = $_ } }
    }

    Context "Json files" {
        ForEach ($file In $testCases) {
            $file.Item('File') | Out-Default
            $fileContent = [System.IO.File]::ReadAllText($File.Item('File'))
            $regexString = [System.Text.RegularExpressions.Regex]::new("^[-\w\._]+$")
            $regexVnetName = [System.Text.RegularExpressions.Regex]::new("-([e|d|t|a|p])-")
            $addressExpression = "^((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))|\*|Internet|AppServiceManagement|AzureCloud|AzureLoadBalancer|GatewayManager|VirtualNetwork|ServiceBus\.WestEurope|ServiceBus\.NorthEurope|Storage|Storage\.WestEurope|Storage\.NorthEurope|Sql|Sql\.WestEurope|Sql\.NorthEurope|EventHub|EventHub\.WestEurope|EventHub\.NorthEurope|AzureCosmosDB|AzureCosmosDB\.WestEurope|AzureCosmosDB\.NorthEurope|AzureDatabricks)$"
            $regexSingleIP = [Text.RegularExpressions.Regex]::new("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
            $regexAddress = [Text.RegularExpressions.Regex]::new($AddressExpression)
            $regexCidr = [Text.RegularExpressions.Regex]::new("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$")

            It "Valid Json file" -TestCases @(@{ "FileContent" = $fileContent }) {
                Param($fileContent)

                $jsonOutput = $fileContent | ConvertFrom-Json -ErrorAction SilentlyContinue
                $jsonOutput | Should -Not -Be $null
            }

            If ($jsonOutput = ($fileContent | ConvertFrom-Json -ErrorAction SilentlyContinue)) {
                # File converted
            }
            Else {
                $jsonOutput = $null
            }

            If ($null -ne $jsonOutput) {
                If ($file.Item('File').ToLower().EndsWith("-nsg.parameters.json")) {
                    Context "Network Security Group" {
                        It "Must have a parameter object" {
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'parameters' }) | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.GetType().Name | Should -Be 'PSCustomObject'
                        }
                        $Global:regexDescription = $null
                        It "Must have parameter vnetName, subnetName and securityRules" {
                            ($jsonOutput.parameters | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'vnetName' -or $_.Name -eq 'subnetName' -or $_.Name -eq 'securityRules' }).Count | Should -Be 3
                            $jsonOutput.parameters.vnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.subnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.securityRules.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.vnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' } | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.subnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' } | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.securityRules | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' } | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.vnetName.value.GetType().Name | Should -Be 'String'
                            $jsonOutput.parameters.subnetName.value.GetType().Name | Should -Be 'String'
                            $jsonOutput.parameters.securityRules.value.GetType().Name | Should -Be 'Object[]'
                            ForEach ($duplicatePriority In ($jsonOutput.parameters.securityRules.value.properties | Select-Object -Property priority, direction | Group-Object -Property priority | Where-Object -FilterScript { $_.Count -gt 1 })) {
                                ($duplicatePriority.Group.direction | Group-Object | Where-Object -FilterScript { $_.Count -gt 1 }) | Should -BeNullOrEmpty -Because "Priority and direction must be unique"
                            }
                            $jsonOutput.parameters.securityRules.value | Select-Object -Property name | ForEach-Object { $_.name.ToLower() } | Group-Object | Where-Object -FilterScript { $_.Count -gt 1 } | Should -BeNullOrEmpty -Because "SecurityRule name must be unique"
                            $regexVnetName.IsMatch($jsonOutput.parameters.vnetName.value) | Should -Be $true
                            $vnetMatch = $regexVnetName.Match($jsonOutput.parameters.vnetName.value)
                            $Global:regexDescription = [System.Text.RegularExpressions.Regex]::new("-($( [String]::Join('|', (@("e", "d", "t", "a", "p") | Where-Object -FilterScript { $_ -ne $vnetMatch.Groups[1].Value })) ))-")
                            $Global:regexDescription | Should -Not -BeNullOrEmpty -Because "A NSG rule name should stay within the same type of network (EDTAP)"
                        }
                        $i = 1
                        ForEach ($securityRule in $jsonOutput.parameters.securityRules.value) {
                            It "Validate rule order number $($i1)" {
                                ($securityRule | Get-Member -MemberType NoteProperty).Count | Should -Be 2
                                ($securityRule | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'name' -or $_.Name -eq 'properties' }).Count | Should -Be 2
                                $securityRule.name.GetType().Name | Should -Be 'String'
                                $securityRule.properties.GetType().Name | Should -Be 'PSCustomObject'
                            }
                            It "Security rule $($securityRule.name)" {
                                $securityRule.name | Should -Not -BeNullOrEmpty
                                $securityRule.name.Length | Should -BeGreaterOrEqual 1
                                $securityRule.name.Length | Should -BeLessOrEqual 80
                                $regexString.IsMatch($securityRule.name) | Should -Be $true
                                $regEx = [Text.RegularExpressions.Regex]::new("^([A-Za-z0-9]+)([A-Za-z0-9-_.]*)([A-Za-z0-9_]+)$")
                                If (!$RegEx.IsMatch($securityRule.name)) {
                                    "Security rule $($securityRule.name)" | Should -Be "securityRules.name should match ^([A-Za-z0-9]+)([A-Za-z0-9-_.]*)([A-Za-z0-9_]+)$"
                                }
                                $securityRule.name | Should -Not -BeLike "*SUBNETNOTFOUND*"
                                $securityRule.name | Should -Not -BeLike "*HOSTNOTFOUND*"
                                ($securityRule.properties | Get-Member -MemberType NoteProperty).Count | Should -Be 9
                                ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'description' -or $_.Name -eq 'protocol' -or $_.Name -eq 'access' -or $_.Name -eq 'priority' -or $_.Name -eq 'direction' } ).Count | Should -Be 5
                                $securityRule.properties.description.GetType().Name | Should -Be 'String'
                                $securityRule.properties.protocol.GetType().Name | Should -Be 'String'
                                $securityRule.properties.access.GetType().Name | Should -Be 'String'
                                $securityRule.properties.priority.GetType().Name | Should -Be 'String' #-BeIn ('Int32', 'Int64')
                                $securityRule.properties.direction.GetType().Name | Should -Be 'String'
                                $securityRule.properties.description.Length | Should -BeLessOrEqual 140
                                $securityRule.properties.protocol | Should -BeIn ('*', 'TCP', 'UDP')
                                $securityRule.properties.access | Should -BeIn ('Allow', 'Deny')
                                $securityRule.properties.priority | Should -BeIn (100..4096)
                                $securityRule.properties.direction | Should -BeIn ('Inbound', 'Outbound')
                                $ruleNameSplit = $securityRule.name.Split('-', 3)
                                ($ruleNameSplit[0] -eq $securityRule.properties.access) | Should -Be $true
                                ($ruleNameSplit[1] -eq $securityRule.properties.direction) | Should -Be $true
                                If ($null -ne $Global:regexDescription) {
                                    $Global:regexDescription.IsMatch($securityRule.properties.description) | Should -Be $false -Because "A NSG rule name should stay within the same type of network (EDTAP)"
                                }
                                Else {
                                    "null value" | Out-Default
                                }

                                # sourceAddressPrefix(es)
                                ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourceAddressPrefix' -or $_.Name -eq 'sourceAddressPrefixes' }).Count | Should -Be 1
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourceAddressPrefix' })) {
                                    $securityRule.properties.sourceAddressPrefix.GetType().Name | Should -Be 'String'
                                    $securityRule.properties.sourceAddressPrefix.Length | Should -BeGreaterThan 0
                                    $regexAddress.IsMatch($securityRule.properties.sourceAddressPrefix) | Should -Be $true
                                    If ($regexCidr.IsMatch($securityRule.properties.sourceAddressPrefix)) {
                                        $addressSpace = $securityRule.properties.sourceAddressPrefix.Split('/')[0]
                                        $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                        $cidr = [System.Convert]::ToInt32($securityRule.properties.sourceAddressPrefix.Split('/')[1])
                                        $cidr | Should -BeIn (0..32)
                                        $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                    }
                                }
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourceAddressPrefixes' })) {
                                    $securityRule.properties.sourceAddressPrefixes.GetType().Name | Should -Be 'Object[]'
                                    $securityRule.properties.sourceAddressPrefixes.Count | Should -BeGreaterThan 0
                                    ForEach ($address In $securityRule.properties.sourceAddressPrefixes) {
                                        $regexAddress.IsMatch($address) | Should -Be $true
                                        If ($regexCidr.IsMatch($address)) {
                                            $addressSpace = $address.Split('/')[0]
                                            $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                            $cidr = [System.Convert]::ToInt32($address.Split('/')[1])
                                            $cidr | Should -BeIn (0..32)
                                            $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                        }
                                    }
                                }
                                # destinationAddressPrefix(es)
                                ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationAddressPrefix' -or $_.Name -eq 'destinationAddressPrefixes' }).Count | Should -Be 1
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationAddressPrefix' })) {
                                    $securityRule.properties.destinationAddressPrefix.GetType().Name | Should -Be 'String'
                                    $securityRule.properties.destinationAddressPrefix.Length | Should -BeGreaterThan 0
                                    $regexAddress.IsMatch($securityRule.properties.destinationAddressPrefix) | Should -Be $true
                                    If ($regexCidr.IsMatch($securityRule.properties.destinationAddressPrefix)) {
                                        $addressSpace = $securityRule.properties.destinationAddressPrefix.Split('/')[0]
                                        $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                        $cidr = [System.Convert]::ToInt32($securityRule.properties.destinationAddressPrefix.Split('/')[1])
                                        $cidr | Should -BeIn (0..32)
                                        $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                    }
                                }
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationAddressPrefixes' })) {
                                    $securityRule.properties.destinationAddressPrefixes.GetType().Name | Should -Be 'Object[]'
                                    $securityRule.properties.destinationAddressPrefixes.Count | Should -BeGreaterThan 0
                                    ForEach ($address In $securityRule.properties.destinationAddressPrefixes) {
                                        $regexAddress.IsMatch($address) | Should -Be $true
                                        If ($regexCidr.IsMatch($address)) {
                                            $addressSpace = $address.Split('/')[0]
                                            $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                            $cidr = [System.Convert]::ToInt32($address.Split('/')[1])
                                            $cidr | Should -BeIn (0..32)
                                            $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                        }
                                    }
                                }
                                # SourcePort(s)
                                ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourcePortRange' -or $_.Name -eq 'sourcePortRanges' }).Count | Should -Be 1
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourcePortRange' })) {
                                    $securityRule.properties.sourcePortRange.GetType().Name | Should -Be 'String'
                                    $securityRule.properties.sourcePortRange.Length | Should -BeGreaterThan 0
                                }
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'sourcePortRanges' })) {
                                    $securityRule.properties.sourcePortRanges.GetType().Name | Should -Be 'Object[]'
                                    $securityRule.properties.sourcePortRanges.Count | Should -BeGreaterThan 0
                                    ForEach ($port in $securityRule.properties.sourcePortRanges) {
                                        $port.Length | Should -BeGreaterThan 0
                                    }
                                }
                                # DestinationPort(s)
                                ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationPortRange' -or $_.Name -eq 'destinationPortRanges' }).Count | Should -Be 1
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationPortRange' })) {
                                    $securityRule.properties.destinationPortRange.GetType().Name | Should -Be 'String'
                                    $securityRule.properties.destinationPortRange.Length | Should -BeGreaterThan 0
                                }
                                If ($null -ne ($securityRule.properties | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq 'destinationPortRanges' })) {
                                    $securityRule.properties.destinationPortRanges.GetType().Name | Should -Be 'Object[]'
                                    $securityRule.properties.destinationPortRanges.Count | Should -BeGreaterThan 0
                                    ForEach ($port in $securityRule.properties.destinationPortRanges) {
                                        $port.Length | Should -BeGreaterThan 0
                                    }
                                }
                            }
                            $i++
                        }
                    }
                }
                ElseIf ($file.Item('File').ToLower().EndsWith("-routetable.parameters.json")) {
                    Context "Route Table" {
                        It "Must have a parameter object" {
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'parameters' }) | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.GetType().Name | Should -Be 'PSCustomObject'
                            ($jsonOutput.parameters | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'vnetName' -or $_.Name -eq 'subnetName' -or $_.Name -eq 'routes' }).Count | Should -Be 3
                            $jsonOutput.parameters.vnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.subnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.routes.GetType().Name | Should -Be 'PSCustomObject'
                            ($jsonOutput.parameters.vnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.subnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.routes | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            $jsonOutput.parameters.vnetName.value.GetType().Name | Should -Be 'String'
                            $jsonOutput.parameters.subnetName.value.GetType().Name | Should -Be 'String'
                            $jsonOutput.parameters.routes.value.GetType().Name | Should -Be 'Object[]'
                        }
                        ForEach ($route In $jsonOutput.parameters.routes.value) {
                            It "Route $($route.name)" {
                                ($route | Get-Member -MemberType NoteProperty).Count | Should -Be 2
                                ($route | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'name' -or $_.Name -eq 'properties' }).Count | Should -Be 2
                                $route.name.GetType().Name | Should -Be 'String'
                                $route.properties.GetType().Name | Should -Be 'PSCustomObject'
                                ($route.properties | Get-Member -MemberType NoteProperty).Count | Should -BeGreaterOrEqual 2
                                ($route.properties | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'addressPrefix' -or $_.Name -eq 'nextHopType' }).Count | Should -Be 2
                                $route.properties.addressPrefix.GetType().Name | Should -Be 'String'
                                $route.properties.nextHopType.GetType().Name | Should -Be 'String'
                                $regexAddress.IsMatch($route.properties.addressPrefix) | Should -Be $true
                                If ($regexCidr.IsMatch($route.properties.addressPrefix)) {
                                    $addressSpace = $route.properties.addressPrefix.Split('/')[0]
                                    $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                    $cidr = [System.Convert]::ToInt32($route.properties.addressPrefix.Split('/')[1])
                                    $cidr | Should -BeIn (0..32)
                                    $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                }
                                $route.properties.nextHopType | Should -BeIn ('VirtualNetworkGateway', 'VnetLocal', 'Internet', 'VirtualAppliance', 'None')
                                If ($route.properties.nextHopType -ne 'Internet' -and $route.properties.nextHopType -ne 'None') {
                                    ($route.properties | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'nextHopIpAddress' }).Count | Should -Be 1
                                    $route.properties.nextHopIpAddress.GetType().Name | Should -Be 'String'
                                    $regexSingleIP.IsMatch($route.properties.nextHopIpAddress) | Should -Be $true
                                }
                            }
                        }
                        #$jsonOutput.parameters | ConvertTo-Json -Depth 100 | Out-Default
                    }
                }
                ElseIf ($file.Item('File').ToLower().EndsWith("\vnet.parameters.json")) {
                    Context "Virtual Network" {
                        It "Must have a parameter object" {
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'parameters' }) | Should -Not -BeNullOrEmpty
                            $jsonOutput.parameters.GetType().Name | Should -Be 'PSCustomObject'
                            ($jsonOutput.parameters | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'vnetName' -or $_.Name -eq 'vnetAddressPrefix' -or $_.Name -eq 'subnetName' -or $_.Name -eq 'subnetAddressPrefix' -or $_.Name -eq 'subnetServiceEndpoints' }).Count | Should -Be 5
                            $jsonOutput.parameters.vnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.vnetAddressPrefix.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.subnetName.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.subnetAddressPrefix.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.parameters.subnetServiceEndpoints.GetType().Name | Should -Be 'PSCustomObject'
                            ($jsonOutput.parameters.vnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.vnetAddressPrefix | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.subnetName | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.subnetAddressPrefix | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            ($jsonOutput.parameters.subnetServiceEndpoints | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                            $jsonOutput.parameters.vnetName.value.GetType().Name | Should -Be 'String'
                            $jsonOutput.parameters.vnetAddressPrefix.value.GetType().Name | Should -Be 'Object[]'
                            $jsonOutput.parameters.subnetName.value.GetType().Name | Should -Be 'Object[]'
                            $jsonOutput.parameters.subnetAddressPrefix.value.GetType().Name | Should -Be 'Object[]'
                            $jsonOutput.parameters.subnetServiceEndpoints.value.GetType().Name | Should -Be 'Object[]'
                        }
                        $Global:vnetAddressPrefixBits = @()
                        It "vnetAddressPrefix" {
                            ($jsonOutput.parameters.vnetAddressPrefix.value.Count -ge 0) | Should -Be $true
                            ForEach ($address In $jsonOutput.parameters.vnetAddressPrefix.value) {
                                $regexAddress.IsMatch($address) | Should -Be $true
                                If ($regexCidr.IsMatch($address)) {
                                    $addressSpace = $address.Split('/')[0]
                                    $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                    $cidr = [System.Convert]::ToInt32($address.Split('/')[1])
                                    $cidr | Should -BeIn (0..32)
                                    $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                    $Global:vnetAddressPrefixBits += $addressSpaceBits.Substring(0, $cidr)
                                }
                            }
                        }
                        It "subnetName" {
                            ($jsonOutput.parameters.subnetName.value.Count -eq $jsonOutput.parameters.subnetAddressPrefix.value.Count) | Should -Be $true
                            ($jsonOutput.parameters.subnetName.value.Count -eq $jsonOutput.parameters.subnetServiceEndpoints.value.Count) | Should -Be $true
                            ForEach ($subnetName In $jsonOutput.parameters.subnetName.value) {
                                ($subnetName.ToLower().EndsWith("-subnet") -or $subnetName -eq 'AzureFirewallSubnet' -or $subnetName -eq 'GatewaySubnet' -or $subnetName -eq 'AzureBastionSubnet') | Should -Be $true
                            }
                        }
                        It "subnetAddressPrefix" {
                            ForEach ($address In $jsonOutput.parameters.subnetAddressPrefix.value) {
                                $regexAddress.IsMatch($address) | Should -Be $true
                                If ($regexCidr.IsMatch($address)) {
                                    $addressSpace = $address.Split('/')[0]
                                    $addressSpaceBits = [System.String]::Join("", ($addressSpace.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
                                    $cidr = [System.Convert]::ToInt32($address.Split('/')[1])
                                    $cidr | Should -BeIn (0..32)
                                    $addressSpaceBits.Substring($cidr, 32 - $cidr) | Should -Be ("").PadRight(32 - $cidr, '0')
                                    $subnetAddressPrefixBits = $addressSpaceBits.Substring(0, $Cidr)
                                    $subnetAddressWithinVnetAddressPrefix = $false
                                    $vnetAddressPrefixBits | ForEach-Object {
                                        If ($subnetAddressPrefixBits.Length -ge $_.Length) {
                                            If ($_ -eq $subnetAddressPrefixBits.Substring(0, $_.Length)) {
                                                $subnetAddressWithinVnetAddressPrefix = $true
                                            }
                                        }
                                    }
                                    $subnetAddressWithinVnetAddressPrefix | Should -Be $true -Because "$($address) should be specified within a vnetAddressPrefix value ($([System.String]::Join(', ', $jsonOutput.parameters.vnetAddressPrefix.value)))"
                                }
                            }
                        }
                        It "subnetServiceEndpoints" {
                            ForEach ($serviceEndpoint In $jsonOutput.parameters.subnetServiceEndpoints.value) {
                                $serviceEndpoint.GetType().Name | Should -Be 'Object[]'
                                ForEach ($serviceEndpointItem In $serviceEndpoint) {
                                    $serviceEndpointItem.GetType().Name | Should -Be 'PSCustomObject'
                                    Switch (($serviceEndpointItem | Get-Member -MemberType NoteProperty).Count) {
                                        1 {
                                            ($serviceEndpointItem | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'service' }).Count | Should -Be 1
                                            $serviceEndpointItem.service.GetType().Name | Should -Be 'String'
                                            $serviceEndpointItem.service | Should -BeIn ('Microsoft.Storage', 'Microsoft.Sql')
                                        }
                                        2 {
                                            ($serviceEndpointItem | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'service' -or $_.Name -eq 'locations' }).Count | Should -Be 2
                                            $serviceEndpointItem.service.GetType().Name | Should -Be 'String'
                                            $serviceEndpointItem.service | Should -BeIn ('Microsoft.Storage', 'Microsoft.Sql', 'Microsoft.ServiceBus', 'Microsoft.EventHub', 'Microsoft.AzureCosmosDB', 'AzureDatabricks')
                                            $serviceEndpointItem.locations.GetType().Name | Should -Be 'Object[]'
                                            ForEach ($serviceEndpointItemLocation In $serviceEndpointItem.locations) {
                                                $serviceEndpointItemLocation.GetType().Name | Should -Be 'String'
                                                $serviceEndpointItemLocation | Should -BeIn ('northeurope', 'westeurope')
                                            }
                                        }
                                        Default {
                                            ($serviceEndpointItem | Get-Member -MemberType NoteProperty).Count | Should -BeIn (1..2)
                                        }
                                    }
                                }
                            }
                        }
                        if ($null -ne ($jsonOutput.parameters | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'dnsServers' })) {
                            It "dnsServers" {
                                $jsonOutput.parameters.dnsServers.GetType().Name | Should -Be 'PSCustomObject'
                                ($jsonOutput.parameters.dnsServers | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'value' }).Count | Should -Be 1
                                $jsonOutput.parameters.dnsServers.value.GetType().Name | Should -Be 'Object[]'
                                ForEach ($dnsServer In $jsonOutput.parameters.dnsServers.value) {
                                    $regexAddress.IsMatch($dnsServer) | Should -Be $true
                                    ($regexCidr.IsMatch($dnsServer)) | Should -Be $false
                                }
                            }
                        }
                    }
                }
                ElseIf ($file.Item('File').ToLower().EndsWith('resourcegroup.parameters.json')) {
                    Context "Resource Group 2.0" {
                        It "Must have a required options" {
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'ServiceName' }) | Should -Not -BeNullOrEmpty
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'Location' }) | Should -Not -BeNullOrEmpty
                            ($jsonOutput | Get-Member -MemberType NoteProperty | Where-Object -FilterScript { $_.Name -eq 'Tags' }) | Should -Not -BeNullOrEmpty
                            $jsonOutput.ServiceName.GetType().Name | Should -Be 'String'
                            $jsonOutput.Location.GetType().Name | Should -Be 'String'
                        }
                        It "Must have valid Tags" {
                            $jsonOutput.Tags.GetType().Name | Should -Be 'PSCustomObject'
                            $jsonOutput.Tags.'Business Application CI'.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.'Billing code'.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.Provider.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.AppName.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.Environment.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.CIA.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.ContactMail.GetType().Name | Should -Be 'String'
                            $jsonOutput.Tags.ContactPhone.GetType().Name | Should -Be 'String'
                            $regexTag = [Text.RegularExpressions.Regex]::new("^(CI\d{7})|(#{ApplicationCI}#)$")
                            $regexTag.IsMatch($jsonOutput.Tags.'Business Application CI') | Should -Be $true
                            $regexTag = [Text.RegularExpressions.Regex]::new("^([A-Z]{2}[0-9A-Z-]{5,8})|#{BillingCode}#$")
                            $regexTag.IsMatch($jsonOutput.Tags.'Billing code') | Should -Be $true
                            $regexTag = [Text.RegularExpressions.Regex]::new("^(Engineering|Development|Test|Acceptance|Production|#{EnvironmentFullName}#)$")
                            $regexTag.IsMatch($jsonOutput.Tags.'Environment') | Should -Be $true
                            $regexTag = [Text.RegularExpressions.Regex]::new(".*[A-Z]{3}\.[A-Z]{3}\.\d{5}.*")
                            $regexTag.IsMatch($jsonOutput.Tags.'AppName') | Should -Be $false
                            $jsonOutput.Tags.Provider | Should -BeExactly 'CBSP Azure'
                            $regexTag = [Text.RegularExpressions.Regex]::new("^([1-3]{3})|(#{CIArating}#)$")
                            $regexTag.IsMatch($jsonOutput.Tags.'CIA') | Should -Be $true
                            $regexTag = [Text.RegularExpressions.Regex]::new("^((\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*))|(#{EmailAddress}#)$")
                            $regexTag.IsMatch($jsonOutput.Tags.'ContactMail') | Should -Be $true
                            $regexTag = [Text.RegularExpressions.Regex]::new("^(\+\d{8,15})|(#{ContactPhone}#)$")
                            $regexTag.IsMatch($jsonOutput.Tags.'ContactPhone') | Should -Be $true
                        }
                    }
                }
            }
            Else {
                Write-Warning "Invalid Json file $($file.Item('File'))"
            }
        }
    }
}
