<#
.DESCRIPTION
    Prerequisites
        - PowerShell Core (to use the Newtonsoft Json)
        - Repository needs to be local
        - Settings.json needs to exists within the same folder as this script
        - Network-Tests.ps1 needs to exists within the parent folder Tests of this script
        - Virtual network solution folder below the Network subscription
            - Readme.md
    NSG's
        Flow Logs and Traffic Analytics parameters are set based on the Settings.json file. The subscription name is retrieved from the parent folder name of the Readme.md file
        If the NSG parameter file already exists a prompt is displayed with the option to replace the existing file
    After the script is processed a Pester tester is performed on the folder of where the Readme.md file exists

.PARAMETER ReadmeFilePath <String>
    File to the readme markdown file within the network solution

.EXAMPLE
    .\CBSP-Azure\Foundation\Networking\VirtualNetwork\v1.0\DeveloperScripts\Parse-ReadmeMd.ps1 -ReadmeFilePath <Full filepath to the Readme.md file>
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]

[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $true)][String] $ReadmeFilePath,
    [Parameter (Mandatory = $false)][String] $TargetLocation,
    [Parameter (Mandatory = $false)]
    [String] 
    [ValidateSet('a','n','y')]
    $Overwrite = 'n'
)

$ErrorActionPreference = 'Stop'

If ([System.IO.File]::Exists("$($PSScriptRoot)\Settings.json")) {
    $nsgSettings = [System.IO.File]::ReadAllText("$($PSScriptRoot)\Settings.json") | ConvertFrom-Json
}
Else {
    Write-Error "The file '$($PSScriptRoot)\Settings.json' doesn't exists"
}

Function Remove-Characters {
    Param (
        [Parameter (Mandatory = $true)][String] $InputString
    )
    Return $InputString.Replace('`', '').Replace('*', '')
}

Function Get-SubnetName {
    Param (
        [Parameter (Mandatory = $true)] $subnetAddressPrefix
    )

    If ($subnetAddressPrefix.GetType().Name -eq 'String') {
        If ($allSubnets.Contains($subnetAddressPrefix)) {
            If ($allSubnets.Item($subnetAddressPrefix).vnetName.Length -gt 0 -and $allSubnets.Item($subnetAddressPrefix).subnetName.Length -gt 0) {
                If ($vnetFullName -ne $allSubnets.Item($subnetAddressPrefix).vnetName) {
                    Return "$($allSubnets.Item($subnetAddressPrefix).vnetName)-$($allSubnets.Item($subnetAddressPrefix).subnetName)"
                }
                Else {
                    Return $allSubnets.Item($subnetAddressPrefix).subnetName
                }
            }
            Else {
                Return "$($allSubnets.Item($subnetAddressPrefix).vnetName)$($allSubnets.Item($subnetAddressPrefix).subnetName)"
            }
        }
        Else {
            If ($subnetAddressPrefix -eq '*') {
                Return "PublicIPSpace"
            }
            ElseIf ($subnetAddressPrefix -eq 'AppServiceManagement') {
                Return "AppServiceManagement"
            }
            ElseIf ($subnetAddressPrefix -eq 'AzureLoadBalancer') {
                Return "AzureLoadBalancer"
            }
            ElseIf ($subnetAddressPrefix -eq 'GatewayManager') {
                Return "GatewayManager"
            }
            ElseIf ($subnetAddressPrefix -eq 'VirtualNetwork') {
                Return "VirtualNetwork"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("storage")) {
                Return "Azure$($subnetAddressPrefix)"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("sql")) {
                Return "Azure$($subnetAddressPrefix)"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("servicebus")) {
                Return "Azure$($subnetAddressPrefix)"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("eventhub")) {
                Return "Azure$($subnetAddressPrefix)"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("azurecosmos")) {
                Return "$($subnetAddressPrefix)"
            }
            ElseIf ($subnetAddressPrefix.ToLower().StartsWith("azuredatabricks")) {
                Return "$($subnetAddressPrefix)"
            }
            Else {
                If ($subnetAddressPrefix.Contains('/') -eq $false -or ($subnetAddressPrefix.Contains('/') -and $subnetAddressPrefix.EndsWith("/32"))) {
                    $hostAddress = $subnetAddressPrefix.Split('/')[0]
                    If ($resolvedAddress = (Resolve-DnsName -Name $hostAddress -Type PTR)) {
                        $nameHost = $resolvedAddress.NameHost.Split('.')[0].ToLower()
                        Write-Host "  Host: $($nameHost)" -ForegroundColor Yellow
                        Return "Host-$($nameHost)"
                    }
                    Else {
                        Write-Host "  HOSTNOTFOUND: $($subnetAddressPrefix)" -ForegroundColor Yellow
                        Return "HOSTNOTFOUND"
                    }
                }
                Else {
                    Write-Host "  SUBNETNOTFOUND: $($subnetAddressPrefix)" -ForegroundColor Yellow
                    Return "SUBNETNOTFOUND"
                }
            }
        }
    }
    ElseIf ($subnetAddressPrefix.GetType().Name -eq 'String[]') {
        If ($subnetAddressPrefix.Contains("10.232.0.0/24") -and $subnetAddressPrefix.Contains("10.232.2.0/24")) {
            Return "AzurePrivateInfraServices"
        }
        ElseIf ($subnetAddressPrefix.Contains("52.166.243.90/32") -and $subnetAddressPrefix.Contains("52.174.36.244/32")) {
            Return "AzureHDIWestEuropeMgtIPs"
        }
        ElseIf ($subnetAddressPrefix.Contains("13.74.153.132/32") -and $subnetAddressPrefix.Contains("52.164.210.96/32")) {
             Return "AzureHDINorthEuropeMgtIPs"
        }
        ElseIf ($subnetAddressPrefix.Contains("23.99.5.239/32") -and $subnetAddressPrefix.Contains("138.91.141.162/32") -and $subnetAddressPrefix.Contains("168.61.48.131/32") -and $subnetAddressPrefix.Contains("168.61.49.99/32")) {
         Return "AzureHDIGlobalMgtIPs"
        }
        ElseIf ($subnetAddressPrefix.Contains("103.210.234.2/32") -and $subnetAddressPrefix.Contains("103.210.235.2/32")) {
            Return "ERpubNATsMSFT"
           }
        Else {
            ForEach ($subnetAddressPrefixItem In $subnetAddressPrefix) {
                If ($allSubnets.Contains($subnetAddressPrefixItem)) {
                    Write-Host "$($allSubnets.Item($subnetAddressPrefixItem).vnetName)-$($allSubnets.Item($subnetAddressPrefixItem).subnetName)" -ForegroundColor Magenta
                }
            }
            Return [System.String]::Join('.', $subnetAddressPrefix)
        }
    }
    Else {
        Write-Error $subnetAddressPrefix.GetType().Name
    }
}

If ([System.IO.File]::Exists($ReadmeFilePath)) {
    $answer = $Overwrite
    $readmeFileInfo = [System.IO.FileInfo]::new($ReadmeFilePath)

    if($TargetLocation){
        $targetFileInfo = [System.IO.FileInfo]::new($TargetLocation)
    }else{
        $targetFileInfo = $readmeFileInfo
    }

    # Get all information that is required
    $vnetFileNames = [System.IO.Directory]::GetFiles($readmeFileInfo.Directory.Parent.Parent.FullName, "vnet.parameters.json", [System.IO.SearchOption]::AllDirectories)
    $allSubnets = [System.Collections.Specialized.ListDictionary]::new()
    ForEach ($vnetFileName In $vnetFileNames) {
        $vnetFileInfo = [System.IO.FileInfo]::new($vnetFileName)
        $vnetJsonFile = [System.IO.File]::ReadAllText($vnetFileName) | ConvertFrom-Json
        If ([System.IO.File]::Exists("$($vnetFileInfo.Directory.FullName)\ResourceGroup.parameters.json")) {
            $resourceGroupJsonFile = [System.IO.File]::ReadAllText("$($vnetFileInfo.Directory.FullName)\ResourceGroup.parameters.json") | ConvertFrom-Json
            If ([System.String]::IsNullOrWhiteSpace($resourceGroupJsonFile.Environment)) {
                $resourceGroupName = "$($resourceGroupJsonFile.ServiceName)-rg"
            }
            Else {
                $resourceGroupName = "$($resourceGroupJsonFile.ServiceName)-$($resourceGroupJsonFile.Environment)-rg"
            }
        }
        Else {
            $resourceGroupName = ""
        }
        For ($i = 0; $i -lt $vnetJsonFile.parameters.subnetAddressPrefix.value.Count; $i++) {
            $subnetAddressPrefix = $vnetJsonFile.parameters.subnetAddressPrefix.value[$i]
            If ($subnetAddressPrefix.Substring(0, 3) -eq '10.') {
                If (!$allSubnets.Contains($subnetAddressPrefix)) {
                    $allSubnets.Add($subnetAddressPrefix, ([PSCustomObject]@{
                        "resourceGroupName"   = $resourceGroupName
                        "vnetName"            = $vnetJsonFile.parameters.vnetName.value
                        "subnetName"          = $vnetJsonFile.parameters.subnetName.value[$i]
                        "subnetAddressPrefix" = $vnetJsonFile.parameters.subnetAddressPrefix.value[$i]
                    }))
                }
                Else {
                    Write-Host "Subnet address prefix '$($subnetAddressPrefix)' already exists" -ForegroundColor Red
                    Write-Host "Current settings"
                    Write-Host "  Resource Group Name  : $($allSubnets.Item($subnetAddressPrefix).resourceGroupName)"
                    Write-Host "  Virtual Network Name : $($allSubnets.Item($subnetAddressPrefix).vnetName)"
                    Write-Host "  Subnet Name          : $($allSubnets.Item($subnetAddressPrefix).subnetName)"
                    Write-Host "  Address Prefix       : $($allSubnets.Item($subnetAddressPrefix).subnetAddressPrefix)"
                    Write-Host "Item that will not be added"
                    Write-Host "  Resource Group Name  : $($resourceGroupName)"
                    Write-Host "  Virtual Network Name : $($vnetJsonFile.parameters.vnetName.value)"
                    Write-Host "  Subnet Name          : $($vnetJsonFile.parameters.subnetName.value[$i])"
                    Write-Host "  Address Prefix       : $($subnetAddressPrefix)"
                    Write-Error "Duplicate address space $($subnetAddressPrefix)"
                }
            }
        }
    }
    $allSubnets.Add("10.0.0.0/8", ([PSCustomObject]@{
        "vnetName"            = "OnPremIntranet"
        "subnetName"          = ""
        "subnetAddressPrefix" = "10.0.0.0/8"
    }))
    $allSubnets.Add("10.232.0.0/16", ([PSCustomObject]@{
        "vnetName"            = "OtherAzurePrivate"
        "subnetName"          = ""
        "subnetAddressPrefix" = "10.232.0.0/16"
    }))
    $allSubnets.Add("10.232.2.0/24", ([PSCustomObject]@{
        "vnetName"            = "DnsServers"
        "subnetName"          = ""
        "subnetAddressPrefix" = "10.232.2.0/24"
    }))
    $allSubnets.Add("10.120.118.50/32", ([PSCustomObject]@{
        "vnetName"            = "OnPremProxy-LoadBalancer"
        "subnetName"          = ""
        "subnetAddressPrefix" = "10.120.118.50/32"
    }))
    $allSubnets.Add("23.100.0.135/32", ([PSCustomObject]@{
        "vnetName"            = "Databrick-Control-Plane"
        "subnetName"          = ""
        "subnetAddressPrefix" = "23.100.0.135/32"
    }))
    $allSubnets.Add("52.232.19.246/32", ([PSCustomObject]@{
        "vnetName"            = "Databrick-Webapp"
        "subnetName"          = ""
        "subnetAddressPrefix" = "52.232.19.246/32"
    }))
    $allSubnets.Add("87.213.22.0/26", ([PSCustomObject]@{
        "vnetName"            = "AABNL-WSGuest"
        "subnetName"          = ""
        "subnetAddressPrefix" = "87.213.22.0/26"
    }))
    $allSubnets.Add("167.202.0.0/16", ([PSCustomObject]@{
        "vnetName"            = "AABNL-Public-IP"
        "subnetName"          = ""
        "subnetAddressPrefix" = "167.202.0.0/16"
    }))
    $allSubnets.Add("AzureCloud", ([PSCustomObject]@{
        "vnetName"            = "AzurePublic"
        "subnetName"          = ""
        "subnetAddressPrefix" = "AzureCloud"
    }))
    $allSubnets.Add("Sql", ([PSCustomObject]@{
        "vnetName"            = "AzureSql"
        "subnetName"          = ""
        "subnetAddressPrefix" = "Sql"
    }))
    $allSubnets.Add("EventHub", ([PSCustomObject]@{
        "vnetName"            = "AzureEventHub"
        "subnetName"          = ""
        "subnetAddressPrefix" = "EventHub"
    }))
    $allSubnets.Add("Internet", ([PSCustomObject]@{
        "vnetName"            = "Internet"
        "subnetName"          = ""
        "subnetAddressPrefix" = "Internet"
    }))
    # Process current Readme
    $contentDetails = [System.Text.RegularExpressions.Regex]::new("#(.*?)\n#", [System.Text.RegularExpressions.RegexOptions]::Singleline).Matches([System.IO.File]::ReadAllText($ReadmeFilePath))

    $subscriptionName = ""
    $environment = ""
    $vnetName = ""
    $serviceName = ""
    $location = ""
    $allowedLocations = @()
    $businessApplicationCI = ""
    $billingCode = ""
    $provider = ""
    $appName = ""
    $cia = ""
    $contactMail = ""
    $contactPhone = ""

    For ($i = 0; $i -lt $contentDetails.Count; $i++) {
        $contentText = $contentDetails[$i].Groups[1].Value
        $contentLines = $contentText.Split("`r`n")
        If ($contentLines[0] -eq '# Environment Details') {
            Write-Output "== Environment Details =="
            $checkBoxes = [System.Text.RegularExpressions.Regex]::new("- \[X\] (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($contentText)
            $regEx = [Text.RegularExpressions.Regex]::new("Engineering|Management|VDC1|(?i)^(VDC)(?:[1-9][0-9]|[2-9]S$)")
            If ($checkBoxes.Count -eq 2) {
                If ($regEx.Matches((Remove-Characters -InputString $checkBoxes[0].Groups[1].Value))) {
                    $subscriptionName = Remove-Characters -InputString $checkBoxes[0].Groups[1].Value
                    Write-Host "##vso[task.setvariable variable=subscriptionName;isOutput=true]$subscriptionName"
                }
                Else {
                    Write-Warning "Invalid subscription name '$(Remove-Characters -InputString $checkBoxes[0].Groups[1].Value)'"
                }
                If ((@("Engineering", "Development", "Test", "Acceptance", "Production")).Contains((Remove-Characters -InputString $checkBoxes[1].Groups[1].Value))) {
                    $environment = Remove-Characters -InputString $checkBoxes[1].Groups[1].Value
                }
                Else {
                    Write-Warning "Invalid environment name '$(Remove-Characters -InputString $checkBoxes[1].Groups[1].Value)'"
                }
            }
            Else {
                Write-Error "Select a Subscription and Environment"
            }
            $lineOptions = [System.Text.RegularExpressions.Regex]::new("\n- (.*): (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($contentText)

            ForEach ($lineOption In $lineOptions) {
                Switch ($lineOption.Groups[1].Value) {
                    "Virtual Network Name" {
                        $vnetName = Remove-Characters -InputString $lineOption.Groups[2].Value.ToLower()
                        Write-Host "##vso[task.setvariable variable=vnetName;isOutput=true]$vnetName"
                    }
                    "ServiceName" {
                        $serviceName = Remove-Characters -InputString $lineOption.Groups[2].Value.ToLower()
                    }
                    "Location" {
                        $location = Remove-Characters -InputString $lineOption.Groups[2].Value.ToLower()
                    }
                    "Allowed Locations" {
                        $allowedLocations = @((Remove-Characters -InputString $lineOption.Groups[2].Value).ToLower().Replace(' ', '').Split(','))
                    }
                    "Business Application CI" {
                        $businessApplicationCI = Remove-Characters -InputString $lineOption.Groups[2].Value.ToUpper()
                    }
                    "Billing code" {
                        $billingCode = Remove-Characters -InputString $lineOption.Groups[2].Value.ToUpper()
                    }
                    "Provider" {
                        $provider = Remove-Characters -InputString $lineOption.Groups[2].Value
                    }
                    "AppName" {
                        $appName = Remove-Characters -InputString $lineOption.Groups[2].Value
                    }
                    "CIA" {
                        $cia = Remove-Characters -InputString $lineOption.Groups[2].Value
                    }
                    "ContactMail" {
                        $contactMail = Remove-Characters -InputString $lineOption.Groups[2].Value.ToLower()
                    }
                    "ContactPhone" {
                        $contactPhone = Remove-Characters -InputString $lineOption.Groups[2].Value
                    }
                }
            }
            If ([String]::IsNullOrWhiteSpace($vnetName) -or [String]::IsNullOrWhiteSpace($location) -or [String]::IsNullOrWhiteSpace($provider) -or [String]::IsNullOrWhiteSpace($contactMail)) {
                Write-Warning "One or multiple required Resource Group tags have no value"
            }
            If ([String]::IsNullOrWhiteSpace($serviceName)) {
                $serviceName = $vnetName
            }
            $resourceGroupObject = [PSCustomObject]@{
                "ServiceName"              = "$($serviceName)-vnets"
                "Environment"              = If (![String]::IsNullOrWhiteSpace($environment)) { "$($environment.Substring(0, 1).ToLower())" } Else { "" }
                "Location"                 = $location
                "AllowedResourceLocations" = $allowedLocations
                "Tags"                     = [PSCustomObject]@{
                    "Business Application CI" = $businessApplicationCI
                    "Billing code"            = $billingCode
                    "Provider"                = $provider
                    "AppName"                 = $appName
                    "Environment"             = $environment
                    "CIA"                     = $cia
                    "ContactMail"             = $contactMail
                    "ContactPhone"            = $contactPhone
                }
            }
            If (![String]::IsNullOrWhiteSpace($environment)) {
                $resourceGroupName = "$($resourceGroupObject.ServiceName)-$($resourceGroupObject.Environment)-rg"
            }
            Else {
                $resourceGroupName = "$($resourceGroupObject.ServiceName)-rg"
            }

            $fileName = "ResourceGroup.parameters.json"
            $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
            If ([System.IO.File]::Exists($fullFileName)) {
                If ($answer -ne "a") {
                    $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                }
                If ($answer -eq 'y' -or $answer -eq "a") {
                    [System.IO.File]::WriteAllText("$($fullFileName)", ($resourceGroupObject | ConvertTo-Json -Depth 100))
                }
            }
            Else {
                [System.IO.File]::WriteAllText("$($fullFileName)", ($resourceGroupObject | ConvertTo-Json -Depth 100))
            }
        }
        ElseIf ($contentLines[0] -eq ' Virtual Network') {
            Write-Output "== Virtual Network =="
            # Virtual Network name
            If (![System.String]::IsNullOrWhiteSpace($environment)) {
                $vnetFullName = "$($vnetName)-$($environment.Substring(0, 1).ToLower())-vnet"
            }
            Else {
                $vnetFullName = "$($vnetName)-vnet"
            }
            # Virtual Network Address Space
            $addressSpaceRegex = [System.Text.RegularExpressions.Regex]::new("\n- Address Space: (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline)
            If ($addressSpaceRegex.IsMatch($contentText)) {
                $addressSpace = @($addressSpaceRegex.Matches((Remove-Characters -InputString $contentText))[0].Groups[1].Value).Replace(' ', '').Split(',')
            }
            Else {
                $addressSpace = @()
                Write-Warning "No Virtual Network Address Space found"
            }

            $subnetNames = @()
            $subnetAddressPrefixes = @()
            $subnetServiceEndpoints = [System.Collections.ArrayList]::new()
            $subnetDelegations = [System.Collections.ArrayList]::new()
            $subnetDelegationFound = $false
            $tableRegex = [System.Text.RegularExpressions.Regex]::new("\|(.*?)\|(.*?)\|(.*?)\|", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            If ($tableRegex.IsMatch($contentText)) {
                $rows = $tableRegex.Matches($contentText)
                If ($rows.Count -gt 2) {
                    For ($j = 2; $j -lt $rows.Count; $j++) {
                        $subnetNames += $rows[$j].Groups[1].Value
                        $subnetAddressPrefixes += $rows[$j].Groups[2].Value
                        # Service Endpoints
                        If ($rows[$j].Groups[3].Value.Length -gt 0) {
                            $subnetServiceEndpointItems = @()
                            $line = $rows[$j].Groups[3].Value.Replace(' ', '').Replace('`', '')
                            $lines = $line.Split("<br />")[0].Split("<br>")[0].Split("<br/>")
                            ForEach ($line In $lines) {
                                If ($line.Contains(":")) {
                                    $subnetServiceEndpointItem = [PSCustomObject]@{
                                        "service"   = "$($line.Split(':')[0])"
                                        "locations" = @($line.Split(':')[1].Split(','))
                                    }
                                }
                                Else {
                                    $subnetServiceEndpointItem = [PSCustomObject]@{
                                        "service" = "$($line)"
                                    }
                                }
                                $subnetServiceEndpointItems += @($subnetServiceEndpointItem)
                            }
                            [System.Void]$subnetServiceEndpoints.Add($subnetServiceEndpointItems)
                        }
                        Else {
                            [System.Void]$subnetServiceEndpoints.Add([System.Collections.ArrayList]::new())
                        }
                        # Delegations
                        $subnetDelegationItems = @()
                        If ($rows[$j].Groups[1].Value.ToLower().StartsWith('adbpublic')) {
                            $subnetDelegationItem = [PSCustomObject]@{
                                "name"       = "databricks-del-public"
                                "properties" = [PSCustomObject]@{
                                    "serviceName" = "Microsoft.Databricks/workspaces"
                                }
                            }
                            $subnetDelegationItems += $subnetDelegationItem
                            [System.Void]$subnetDelegations.Add($subnetDelegationItems)
                            $subnetDelegationFound = $true
                        }
                        ElseIf ($rows[$j].Groups[1].Value.ToLower().StartsWith('adbprivate')) {
                            $subnetDelegationItem = [PSCustomObject]@{
                                "name"       = "databricks-del-private"
                                "properties" = [PSCustomObject]@{
                                    "serviceName" = "Microsoft.Databricks/workspaces"
                                }
                            }
                            $subnetDelegationItems += $subnetDelegationItem
                            [System.Void]$subnetDelegations.Add($subnetDelegationItems)
                            $subnetDelegationFound = $true
                        }
                        ElseIf ($rows[$j].Groups[1].Value.ToLower().StartsWith('appservice')) {
                            $subnetDelegationItem = [PSCustomObject]@{
                                "name"       = "appservice-regional-vnet-integration"
                                "properties" = [PSCustomObject]@{
                                    "serviceName" = "Microsoft.Web/serverFarms"
                                }
                            }
                            $subnetDelegationItems += $subnetDelegationItem
                            [System.Void]$subnetDelegations.Add($subnetDelegationItems)
                            $subnetDelegationFound = $true
                        }
                        Else {
                            [System.Void]$subnetDelegations.Add([System.Collections.ArrayList]::new())
                        }
                    }
                }
                Else {
                    Write-Warning "No subnets found within the Virtual Network subnet table"
                }
            }
            Else {
                Write-Warning "No Virtual Network table found with subnets"
            }

            For ($j = 0; $j -lt $subnetNames.Count; $j++) {
                If ($subnetAddressPrefixes[$j].Substring(0, 3) -eq '10.') {
                    If (!$allSubnets.Contains($subnetAddressPrefixes[$j])) {
                        $allSubnets.Add($subnetAddressPrefixes[$j], ([PSCustomObject]@{
                            "resourceGroupName"   = $resourceGroupName
                            "vnetName"            = $vnetFullName
                            "subnetName"          = $subnetNames[$j]
                            "subnetAddressPrefix" = $subnetAddressPrefixes[$j]
                        }))
                    }
                    Else {
                        Write-Host "Added address space: $($allSubnets.Item($subnetAddressPrefixes[$j]).vnetName) - $($allSubnets.Item($subnetAddressPrefixes[$j]).subnetName) - $($allSubnets.Item($subnetAddressPrefixes[$j]).subnetAddressPrefix)" -ForegroundColor Yellow
                    }
                }
            }

            $dnsServers = $null
            $checkBoxes = [System.Text.RegularExpressions.Regex]::new("- \[X\] (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($contentText) | Where-Object -FilterScript { $_.Groups[1].Value -ne 'Enforce Subnet-NSG-RT relationship' }
            If ($checkBoxes.Count -eq 1) {
                If ($checkBoxes[0].Groups[1].Value.StartsWith('Azure DNS')) {
                    $dnsServers = @()
                }
                ElseIf ($checkBoxes[0].Groups[1].Value.StartsWith('Azure ADDS')) {
                    $dnsServers = @("10.232.2.4", "10.232.2.5")
                }
                ElseIf ($checkBoxes[0].Groups[1].Value.StartsWith('On-prem Infoblox')) {
                    $dnsServers = @("10.124.237.66", "10.124.226.228")
                }
                ElseIf ($checkBoxes[0].Groups[1].Value.StartsWith('Other: ')) {
                    $dnsServers = @()
                    Write-Warning "Not implemented"
                }
                ElseIf ($checkBoxes[0].Groups[1].Value -eq 'Enforce Subnet-NSG-RT relationship') {
                    Write-Warning "Not implemented"
                    Write-Warning "This implementation is done on the Resource Group level and doesn't have a parameter for this"
                }
            }
            ElseIf ($checkBoxes.Count -eq 0) {
                # No DNS service specified, using default
            }
            Else {
                Write-Warning "Multiple DNS services selected"
                $checkBoxes | ForEach-Object {
                    Write-Host "$($_.Groups[0].Value)"
                }
            }

            If ($nsgLocation = ($nsgSettings.NSGFlowLogs.$subscriptionName.locations | Where-Object -FilterScript { $_.location -eq $location })) {
                $workspaceSubscriptionId = $nsgSettings.NSGFlowLogs.$subscriptionName.workspaceSubscriptionId
                $workspaceResourceGroupName = $nsgSettings.NSGFlowLogs.$subscriptionName.workspaceResourceGroupName
                $workspaceName = $nsgSettings.NSGFlowLogs.$subscriptionName.workspaceName
                $storageAccountResourceGroupName = $nsgSettings.NSGFlowLogs.$subscriptionName.storageAccountResourceGroupName
                $storageAccountName = $nsgLocation.storageAccountName
            }
            Else {
                Write-Error "No NSG configuration information found for Subscription '$subscriptionName' and location '$location'"
            }

            # Virtual Network parameter object
            $parameters = [PSCustomObject]@{
                "vnetName"               = [PSCustomObject]@{
                    "value" = $vnetFullName
                }
                "vnetAddressPrefix"      = [PSCustomObject]@{
                    "value" = @($addressSpace)
                }
                "dnsServers"             = [PSCustomObject]@{
                    "value" = @($dnsServers)
                }
                "subnetName"             = [PSCustomObject]@{
                    "value" = $subnetNames
                }
                "subnetAddressPrefix"    = [PSCustomObject]@{
                    "value" = $subnetAddressPrefixes
                }
                "subnetServiceEndpoints" = [PSCustomObject]@{
                    "value" = @($subnetServiceEndpoints)
                }
                "subnetDelegations"      = [PSCustomObject]@{
                    "value" = @($subnetDelegations)
                }
            }
            If ($null -eq $dnsServers) {
                $parameters = $parameters | Select-Object -Property * -ExcludeProperty dnsServers
            }
            If (!$subnetDelegationFound) {
                $parameters = $parameters | Select-Object -Property * -ExcludeProperty subnetDelegations
            }
            $virtualNetworkObject = [PSCustomObject]@{
                "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                "contentVersion" = "1.0.0.0"
                "parameters"     = $parameters
            }

            $fileName = "Vnet.parameters.json"
            $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
            If ([System.IO.File]::Exists($fullFileName)) {
                If ($answer -ne "a") {
                    $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                }
                If ($answer -eq 'y' -or $answer -eq "a") {
                    [System.IO.File]::WriteAllText("$($fullFileName)", ($virtualNetworkObject | ConvertTo-Json -Depth 100))
                }
            }
            Else {
                [System.IO.File]::WriteAllText("$($fullFileName)", ($virtualNetworkObject | ConvertTo-Json -Depth 100))
            }
        }
        ElseIf ($contentLines[0] -eq '# Peering') {
            Write-Output "== Virtual Network Peering =="
            $checkBoxes = [System.Text.RegularExpressions.Regex]::new("- \[X\] (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($contentText)
            If ($checkBoxes.Count -gt 0) {
                For ($j = 0; $j -lt $checkBoxes.Count; $j++) {
                    $checkBox = $checkBoxes[$j]
                    $checkBox
                    If ($checkBox.Groups[1].Value -eq 'Hub/Spoke') {
                        If ($subscriptionName -eq 'Engineering') {
                            # Virtual Network within the Engineering subscription are by default connected to another Hub Virtual Network within the Management subscription
                            $hubVnetName = "infra06-p-vnet"
                            $hubVnetResourceGroupName = "infra02-vnets-p-rg"
                        }
                        ElseIf ($environment -eq 'Development' -or $environment -eq 'Test') {
                            # Virtual Network within the Development and Test environments are by default connected to another Hub Virtual Network within the Management subscription
                            $hubVnetName = "hubwe07-p-vnet"
                            $hubVnetResourceGroupName = "hubwe07-p-rg"
                        }
                        Else {
                            $hubVnetName = "infra01-vnet"
                            $hubVnetResourceGroupName = "infra-vnets-p-rg"
                        }
                        # VnetPeering.parameters.json
                        $vnetPeeringObject = [PSCustomObject]@{
                            "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                            "contentVersion" = "1.0.0.0"
                            "parameters"     = [PSCustomObject]@{
                                "vnetName"              = [PSCustomObject]@{
                                    "value" = $vnetFullName
                                }
                                "peerVnetName"          = [PSCustomObject]@{
                                    "value" = $hubVnetName
                                }
                                "peerVnetResourceGroup" = [PSCustomObject]@{
                                    "value" = $hubVnetResourceGroupName
                                }
                            }
                        }
                        $fileName = "VnetPeering.parameters.json"
                        $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                        If ([System.IO.File]::Exists($fullFileName)) {
                            If ($answer -ne "a") {
                                $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                            }
                            If ($answer -eq 'y' -or $answer -eq "a") {
                                [System.IO.File]::WriteAllText("$($fullFileName)", ($vnetPeeringObject | ConvertTo-Json -Depth 100))
                            }
                        }
                        Else {
                            [System.IO.File]::WriteAllText("$($fullFileName)", ($vnetPeeringObject | ConvertTo-Json -Depth 100))
                        }
                        # PeerVnetPeering.parameters.json
                        $peerVnetPeeringObject = [PSCustomObject]@{
                            "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                            "contentVersion" = "1.0.0.0"
                            "parameters"     = [PSCustomObject]@{
                                "allowVirtualNetworkAccess" = [PSCustomObject]@{
                                    "value" = $true
                                }
                                "allowForwardedTraffic"     = [PSCustomObject]@{
                                    "value" = $true
                                }
                                "allowGatewayTransit"       = [PSCustomObject]@{
                                    "value" = $true
                                }
                                "useRemoteGateways"         = [PSCustomObject]@{
                                    "value" = $false
                                }
                            }
                        }
                        $fileName = "PeerVnetPeering.parameters.json"
                        $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                        If ([System.IO.File]::Exists($fullFileName)) {
                            If ($answer -ne "a") {
                                $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                            }
                            If ($answer -eq 'y' -or $answer -eq "a") {
                                [System.IO.File]::WriteAllText("$($fullFileName)", ($peerVnetPeeringObject | ConvertTo-Json -Depth 100))
                            }
                        }
                        Else {
                            [System.IO.File]::WriteAllText("$($fullFileName)", ($peerVnetPeeringObject | ConvertTo-Json -Depth 100))
                        }
                    }
                    ElseIf ($checkBox.Groups[1].Value -eq 'Spoke/Spoke') {
                        # Identify spoke peering regular expression needs to be made
                        $spokeRegex = [System.Text.RegularExpressions.Regex]::new("``(.*)``.*``(.*)``.*``(.*)``")
                        $j++
                        While ($j -lt $checkBoxes.Count) {
                            $checkBox = $checkBoxes[$j]
                            # Validate the spoke peering line and create parameter files
                            If ($spokeRegex.IsMatch($checkBox.Value)) {
                                $spokePeeringParameters = $spokeRegex.Matches($checkBox.Value)
                                $spokePeering = [PSCustomObject]@{
                                    "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                                    "contentVersion" = "1.0.0.0"
                                    "parameters"     = [PSCustomObject]@{
                                        "vnetName"                  = [PSCustomObject]@{
                                            "value" = $vnetFullName
                                        }
                                        "peerVnetName"              = [PSCustomObject]@{
                                            "value" = $spokePeeringParameters.Groups[1].Value
                                        }
                                        "peerVnetResourceGroup"     = [PSCustomObject]@{
                                            "value" = $spokePeeringParameters.Groups[2].Value
                                        }
                                        "peerVnetSubscriptionId"    = [PSCustomObject]@{
                                            "value" = $spokePeeringParameters.Groups[3].Value
                                        }
                                        "allowVirtualNetworkAccess" = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "allowForwardedTraffic"     = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                        "allowGatewayTransit"       = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                        "useRemoteGateways"         = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                    }
                                }
                                $fileName = "VnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"
                                $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                                If ([System.IO.File]::Exists($fullFileName)) {
                                    If ($answer -ne "a") {
                                        $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                                    }
                                    If ($answer -eq 'y' -or $answer -eq "a") {
                                        [System.IO.File]::WriteAllText("$($fullFileName)", ($spokePeering | ConvertTo-Json -Depth 100))
                                    }
                                }
                                Else {
                                    [System.IO.File]::WriteAllText("$($fullFileName)", ($spokePeering | ConvertTo-Json -Depth 100))
                                }

                                $spokePeering = [PSCustomObject]@{
                                    "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                                    "contentVersion" = "1.0.0.0"
                                    "parameters"     = [PSCustomObject]@{
                                        "allowVirtualNetworkAccess" = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "allowForwardedTraffic"     = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                        "allowGatewayTransit"       = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                        "useRemoteGateways"         = [PSCustomObject]@{
                                            "value" = $false
                                        }
                                    }
                                }
                                $fileName = "PeerVnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"
                                $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                                If ([System.IO.File]::Exists($fullFileName)) {
                                    If ($answer -ne "a") {
                                        $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                                    }
                                    If ($answer -eq 'y' -or $answer -eq "a") {
                                        [System.IO.File]::WriteAllText("$($fullFileName)", ($spokePeering | ConvertTo-Json -Depth 100))
                                    }
                                }
                                Else {
                                    [System.IO.File]::WriteAllText("$($fullFileName)", ($spokePeering | ConvertTo-Json -Depth 100))
                                }
                            }
                            Else {
                                Write-Error "'$($checkbox.Value)' is not a valid Spoke/Spoke peering"
                            }
                            $j++
                        }
                    }
                }
            }
            Else {
                $fileName = "VnetPeering.parameters.json"
                $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                If ([System.IO.File]::Exists($fullFileName)) {
                    $answer = Read-Host -Prompt "Remove file '$($fullFileName)' (y/n)"
                    If ($answer -eq 'y') {
                        [System.IO.File]::Delete($fullFileName)
                    }
                }

                $fileName = "PeerVnetPeering.parameters.json"
                $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                If ([System.IO.File]::Exists($fullFileName)) {
                    $answer = Read-Host -Prompt "Remove file '$($fullFileName)' (y/n)"
                    If ($answer -eq 'y') {
                        [System.IO.File]::Delete($fullFileName)
                    }
                }
            }
        }
        ElseIf ($contentLines[0] -eq '# Route Tables') {
            Write-Output "== Virtual Network Route Tables =="
            # M365-Common ID 56
            $checkBoxes = [System.Text.RegularExpressions.Regex]::new("- \[X\] (.*)\r", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($contentText)
            $m365Subnets = @()
            $m365Routes = @()
            If ($checkBoxes.Count -gt 0) {
                If ($checkBoxes[0].Groups[1].Value.ToUpper().StartsWith("M365-COMMON ID 56: ")) {
                    $nextHopType = 'VirtualAppliance'
                    $nextHopIpAddress = $checkBoxes[0].Groups[1].Value.Substring(19)
                    For ($j = 1; $j -lt $checkBoxes.Count; $j++) {
                        If ($subnetNames.Contains($checkBoxes[$j].Groups[1].Value.ToLower())) {
                            $m365Subnets += $checkBoxes[$j].Groups[1].Value.ToLower()
                        }
                        Else {
                            Write-Warning "Subnet '$($checkBoxes[$j].Groups[1].Value.ToLower())' doesn't exists"
                        }
                    }
                    If (@($m365Subnets).Count -gt 0) {
                        $requestId = [System.Guid]::NewGuid().Guid
                        $endpoints = Invoke-RestMethod -Uri "https://endpoints.office.com/endpoints/Worldwide?ClientRequestId=$requestId&NoIPv6=true" -Method Get -UseBasicParsing
                        $endpoint = $endpoints | Where-Object -FilterScript { $_.id -eq 56 }
                        $j = 1
                        ForEach ($ip In $endpoint.ips) {
                            $route = [PSCustomObject]@{
                                'name'       = "M365-Common-Required-$($j.ToString("00"))"
                                'properties' = [PSCustomObject]@{
                                    'addressPrefix'    = $ip
                                    'nextHopType'      = $nextHopType
                                    'nextHopIpAddress' = $nextHopIpAddress
                                }
                            }
                            $m365Routes += $route
                            $j++
                        }
                    }
                }
            }
            # Process subnets
            $tableRegex = [System.Text.RegularExpressions.Regex]::new("\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            ForEach ($checkBox In ($checkBoxes | Where-Object { $_.Groups[1].Value.ToUpper().StartsWith("M365-COMMON ID 56: ") -eq $false })) {
                Write-Output "  Process subnet: $($checkBox.Groups[1].Value)"
                If ($subnetNames.Contains($checkBox.Groups[1].Value)) {
                    $routes = $m365Routes
                    $subnetName = $checkBox.Groups[1].Value.ToLower()

                    $routeTableObject = [PSCustomObject]@{
                        '$schema'        = 'http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#'
                        'contentVersion' = '1.0.0.0'
                        'parameters'     = [PSCustomObject]@{
                            "vnetName"   = [PSCustomObject]@{
                                "value" = $vnetFullName
                            }
                            "subnetName" = [PSCustomObject]@{
                                "value" = $subnetName
                            }
                            "routes"     = [PSCustomObject]@{
                                "value" = @($routes)
                            }
                        }
                    }

                    $fileName = "$($vnetFullName)-$($subnetName)-routetable.parameters.json"
                    $fileName
                    $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                    If ([System.IO.File]::Exists($fullFileName)) {
                        If ($answer -ne "a") {
                            $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                        }
                        If ($answer -eq 'y' -or $answer -eq "a") {
                            [System.IO.File]::WriteAllText("$($fullFileName)", ($routeTableObject | ConvertTo-Json -Depth 100))
                        }
                    }
                    Else {
                        [System.IO.File]::WriteAllText("$($fullFileName)", ($routeTableObject | ConvertTo-Json -Depth 100))
                    }
                }
                Else {
                    Write-Host "  Subnet $($checkBox.Groups[1].Value) not found" -ForegroundColor Red
                }
            }
            While ($i -lt $contentDetails.Count) {
                $i++
                $contentText = $contentDetails[$i].Groups[1].Value
                $contentLines = $contentText.Split("`r`n")
                If ($contentLines[0].Length -gt 6 -and $subnetNames.Contains($contentLines[0].Substring(6).ToLower())) {
                    $subnetName = $contentLines[0].Substring(6).ToLower()
                    Write-Output "  Process subnet with custom routes: $($subnetName)"
                    If ($tableRegex.IsMatch($contentText)) {
                        $rows = $tableRegex.Matches($contentText)
                        $routes = @()
                        If ($rows.Count -gt 2) {
                            For ($j = 2; $j -lt $rows.Count; $j++) {
                                $route = [PSCustomObject]@{
                                    'name'       = "$($rows[$j].Groups[1].Value)"
                                    'properties' = [PSCustomObject]@{
                                        'addressPrefix'    = $rows[$j].Groups[2].Value
                                        'nextHopType'      = $rows[$j].Groups[3].Value
                                        'nextHopIpAddress' = $rows[$j].Groups[4].Value
                                    }
                                }
                                $routes += $route
                            }
                        }
                        If ($m365Subnets.Contains($subnetName)) {
                            $routes += $m365Routes
                        }
                        If (@($routes).Count -gt 0) {
                            $routeTableObject = [PSCustomObject]@{
                                '$schema'        = 'http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#'
                                'contentVersion' = '1.0.0.0'
                                'parameters'     = [PSCustomObject]@{
                                    "vnetName"   = [PSCustomObject]@{
                                        "value" = $vnetFullName
                                    }
                                    "subnetName" = [PSCustomObject]@{
                                        "value" = $subnetName
                                    }
                                    "routes"     = [PSCustomObject]@{
                                        "value" = @($routes)
                                    }
                                }
                            }

                            $fileName = "$($vnetFullName)-$($subnetName)-routetable.parameters.json"
                            $fileName
                            $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                            If ([System.IO.File]::Exists($fullFileName)) {
                                If ($answer -ne "a") {
                                    $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                                }
                                If ($answer -eq 'y' -or $answer -eq "a") {
                                    [System.IO.File]::WriteAllText("$($fullFileName)", ($routeTableObject | ConvertTo-Json -Depth 100))
                                }
                            }
                            Else {
                                [System.IO.File]::WriteAllText("$($fullFileName)", ($routeTableObject | ConvertTo-Json -Depth 100))
                            }
                        }
                    }
                }
                Else {
                    $i--
                    Break
                }
            }
        }
        ElseIf ($contentLines[0] -eq '# Network Security Group') {
            Write-Output "== Virtual Network Security Group =="
            $tableRegex = [System.Text.RegularExpressions.Regex]::new("\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            While ($i -lt $contentDetails.Count) {
                $i++
                $contentText = $contentDetails[$i].Groups[1].Value
                $contentLines = $contentText.Split("`r`n")
                $contentLines[0]
                If ($contentLines[0].Length -gt 7 -and $subnetNames.Contains($contentLines[0].Substring(7).ToLower())) {
                    $subnetName = $contentLines[0].Substring(7).ToLower()
                    "$($vnetFullName)-$($subnetName)"
                    If ($tableRegex.IsMatch($contentText) ) {
                        $rows = $tableRegex.Matches($contentText)
                        If ($rows.Count -gt 2) {
                            $nsgRuleItems = @()
                            For ($j = 2; $j -lt $rows.Count; $j++) {
                                $nsgRuleItem = @{ }
                                For ($k = 1; $k -lt $rows[0].Groups.Count; $k++) {
                                    $nsgRuleItem.Add($rows[0].Groups[$k].Value, $rows[$j].Groups[$k].Value.Replace('`', '').Replace('**', ''))
                                }
                                If ($nsgRuleItem.'From address'.Contains(',')) {
                                    $nsgRuleItem.'From address' = $nsgRuleItem.'From address'.Replace(' ', '')
                                    $nsgRuleItem.'From address' = $nsgRuleItem.'From address'.Split(',')
                                }
                                If ($nsgRuleItem.'To address'.Contains(',')) {
                                    $nsgRuleItem.'To address' = $nsgRuleItem.'To address'.Replace(' ', '')
                                    $nsgRuleItem.'To address' = $nsgRuleItem.'To address'.Split(',')
                                }
                                If ($nsgRuleItem.'From port'.Contains(',')) {
                                    $nsgRuleItem.'From port' = $nsgRuleItem.'From port'.Replace(' ', '')
                                    $nsgRuleItem.'From port' = $nsgRuleItem.'From port'.Split(',')
                                }
                                If ($nsgRuleItem.'To port'.Contains(',')) {
                                    $nsgRuleItem.'To port' = $nsgRuleItem.'To port'.Replace(' ', '')
                                    $nsgRuleItem.'To port' = $nsgRuleItem.'To port'.Split(',')
                                }
                                $nsgRuleItem.Priority = [Int32]::Parse($nsgRuleItem.Priority)
                                $nsgRuleItems += $nsgRuleItem
                            }

                            # Process the rules to a NSG parameter file
                            $nsgSecurityRules = @()
                            ForEach ($nsgRuleItem In ($nsgRuleItems | Sort-Object -Property Direction, Priority)) {
                                # Access
                                # $nsgRuleItem.Access.Replace('*', 'Any')
                                $protocol = "*"
                                If ($nsgRuleItem.'To port'.Count -gt 1) {
                                    If ($nsgRuleItem.'To port'.Contains("80") -and $nsgRuleItem.'To port'.Contains("443")) {
                                        $ruleAccessName = "HTTP-S"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("1433") -and $nsgRuleItem.'To port'.Contains("11000-11999")) {
                                        $ruleAccessName = "AzureSQL"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("4040") -and $nsgRuleItem.'To port'.Contains("4050")) {
                                        $ruleAccessName = "Spark"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("9094") -and $nsgRuleItem.'To port'.Contains("9095") -and $nsgRuleItem.'To port'.Contains("9096")) {
                                        $ruleAccessName = "KAFKA"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("454-455") -and $nsgRuleItem.'To port'.Contains("16001")) {
                                        $ruleAccessName = "ASEManagement"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("135") -and $nsgRuleItem.'To port'.Contains("139") -and $nsgRuleItem.'To port'.Contains("445")) {
                                        $ruleAccessName = "Windows"
                                        $protocol = "TCP"
                                    }
                                    ElseIf ($nsgRuleItem.'To port'.Contains("443") -and $nsgRuleItem.'To port'.Contains("5671") -and $nsgRuleItem.'To port'.Contains("5672") -and $nsgRuleItem.'To port'.Contains("9350-9354")) {
                                        $ruleAccessName = "Messaging"
                                        $protocol = "TCP"
                                    }
                                    Else {
                                        $ruleAccessName = "?"
                                        Write-Host ($nsgRuleItem | ConvertTo-Json -Depth 100) -ForegroundColor Red
                                    }
                                }
                                Else {
                                    If ($nsgRuleItem.'From port' -eq '*' -and $nsgRuleItem.'To port' -eq '*') {
                                        $ruleAccessName = "Any"
                                    }
                                    Else {
                                        If ($nsgRuleItem.'From port' -eq '*') {
                                            If ($nsgRuleItem.'To port' -eq '22') {
                                                $ruleAccessName = "SSH"
                                                If ($nsgRuleItem.'From address' -ne '23.100.0.135/32') {
                                                    # Non Databrick-Control-Plane SSH traffic uses the TCP protocol
                                                    $protocol = "TCP"
                                                }
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '22-23') {
                                                $ruleAccessName = "SSH"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '53') {
                                            $ruleAccessName = "DNS"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '80') {
                                                $ruleAccessName = "HTTP"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '123') {
                                                $ruleAccessName = "NTP"
                                                $protocol = "UDP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '443') {
                                                $ruleAccessName = "HTTPS"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '454-455') {
                                                $ruleAccessName = "ASEManagement"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '3389') {
                                                $ruleAccessName = "RDP"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '5000') {
                                                $ruleAccessName = "PortainerWebUI"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '5557') {
                                                $ruleAccessName = "WorkerProxy"
                                                $protocol = "*"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '8080') {
                                                $ruleAccessName = "HTTPProxy"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '8088') {
                                                $ruleAccessName = "ZeppelinNotebookWebUI"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '8161') {
                                                $ruleAccessName = "ActiveMQWebUI"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '50070') {
                                                $ruleAccessName = "HadoopWebUI"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '65503-65534') {
                                                $ruleAccessName = "HealthProbe"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '9093') {
                                                $ruleAccessName = "EventHub"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '9092') {
                                                $ruleAccessName = "KAFKA"
                                                $protocol = "TCP"
                                            }
                                            ElseIf ($nsgRuleItem.'To port' -eq '3306') {
                                                    $ruleAccessName = "SQL"
                                                    $protocol = "TCP"
                                            }
                                            Else {
                                                $ruleAccessName = "TCP$($nsgRuleItem.'To port')"
                                                $protocol = "TCP"
                                                Write-Host $ruleAccessName -ForegroundColor Yellow
                                                Write-Host ($nsgRuleItem | ConvertTo-Json -Depth 100) -ForegroundColor Red
                                            }
                                        }
                                        ElseIf ($nsgRuleItem.'From port' -eq '65503-65534') {
                                            $ruleAccessName = "HealtProbe"
                                            $protocol = "TCP"
                                        }
                                        ElseIf ($nsgRuleItem.'To port' -eq '*') {
                                            If ($nsgRuleItem.'From port' -eq '65503-65534') {
                                                $ruleAccessName = "HealtProbe"
                                                $protocol = "TCP"
                                            }
                                            Else {
                                                $ruleAccessName = "?"
                                                Write-Host ($nsgRuleItem | ConvertTo-Json -Depth 100) -ForegroundColor Red
                                            }
                                        }
                                        Else {
                                            $ruleAccessName = "?"
                                            Write-Host ($nsgRuleItem | ConvertTo-Json -Depth 100) -ForegroundColor Red
                                        }
                                    }
                                }
                                # From or To
                                $ruleNameDirection = "Unknown"
                                $lastItem = "Unknown"
                                If ($nsgRuleItem.Direction -eq 'Inbound') {
                                    If ($nsgRuleItem.'To address' -eq '*' -and $nsgRuleItem.'From address' -eq '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "Other-Traffic"
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -eq $nsgRuleItem.'From address') {
                                        $ruleNameDirection = ""
                                        $lastItem = "IntraSubnet-Traffic"
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -ne '*' -and $nsgRuleItem.'From address' -ne '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'From address')-to-$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'To address')"
                                    }
                                    ElseIf ($nsgRuleItem.'From address' -ne '*') {
                                        $ruleNameDirection = "from-"
                                        $lastItem = Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'From address'
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -ne '*') {
                                        $ruleNameDirection = "to-"
                                        $lastItem = Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'To address'
                                    }
                                }
                                ElseIf ($nsgRuleItem.Direction -eq 'Outbound') {
                                    If ($nsgRuleItem.'To address' -eq '*' -and $nsgRuleItem.'From address' -eq '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "Other-Traffic"
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -eq $nsgRuleItem.'From address') {
                                        $ruleNameDirection = ""
                                        $lastItem = "IntraSubnet-Traffic"
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -ne '*' -and $nsgRuleItem.'From address' -ne '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'From address')-to-$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'To address')"
                                    }
                                    ElseIf ($nsgRuleItem.'To address' -ne '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "to-$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'To address')"
                                    }
                                    ElseIf ($nsgRuleItem.'From address' -ne '*') {
                                        $ruleNameDirection = ""
                                        $lastItem = "$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'From address')-to-$(Get-SubnetName -subnetAddressPrefix $nsgRuleItem.'To address')"
                                    }
                                }
                                $ruleName = "$($nsgRuleItem.Access)-$($nsgRuleItem.Direction)-$($ruleAccessName)-$($ruleNameDirection)$($lastItem)"
                                $nsgSecurityRule = [PSCustomObject]@{
                                    "name"       = $ruleName
                                    "properties" = [PSCustomObject]@{
                                        "description"                = $nsgRuleItem.Name
                                        "protocol"                   = $protocol
                                        "sourcePortRange"            = $nsgRuleItem.'From port'
                                        "sourcePortRanges"           = $nsgRuleItem.'From port'
                                        "destinationPortRange"       = $nsgRuleItem.'To port'
                                        "destinationPortRanges"      = $nsgRuleItem.'To port'
                                        "sourceAddressPrefix"        = $nsgRuleItem.'From address'
                                        "sourceAddressPrefixes"      = $nsgRuleItem.'From address'
                                        "destinationAddressPrefix"   = $nsgRuleItem.'To address'
                                        "destinationAddressPrefixes" = $nsgRuleItem.'To address'
                                        "access"                     = $nsgRuleItem.Access
                                        "priority"                   = $nsgRuleItem.Priority.ToString()
                                        "direction"                  = $nsgRuleItem.Direction
                                    }
                                }
                                # Remove properties
                                If ($nsgSecurityRule.properties.sourcePortRanges.Count -gt 1) {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty sourcePortRange
                                }
                                Else {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty sourcePortRanges
                                }
                                If ($nsgSecurityRule.properties.destinationPortRanges.Count -gt 1) {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty destinationPortRange
                                }
                                Else {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty destinationPortRanges
                                }
                                If ($nsgSecurityRule.properties.sourceAddressPrefixes.Count -gt 1) {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty sourceAddressPrefix
                                }
                                Else {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty sourceAddressPrefixes
                                }
                                If ($nsgSecurityRule.properties.destinationAddressPrefixes.Count -gt 1) {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty destinationAddressPrefix
                                }
                                Else {
                                    $nsgSecurityRule.properties = $nsgSecurityRule.properties | Select-Object -Property * -ExcludeProperty destinationAddressPrefixes
                                }
                                $nsgSecurityRules += $nsgSecurityRule
                            }

                            If (![String]::IsNullOrWhiteSpace($workspaceSubscriptionId)) {
                                $nsgFileObject = [PSCustomObject]@{
                                    "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                                    "contentVersion" = "1.0.0.0"
                                    "parameters"     = [PSCustomObject]@{
                                        "vnetName"                        = [PSCustomObject]@{
                                            "value" = $vnetFullName
                                        }
                                        "subnetName"                      = [PSCustomObject]@{
                                            "value" = $subnetName
                                        }
                                        "enableFlowLogs"                  = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "enableTrafficAnalytics"          = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "storageAccountResourceGroupName" = [PSCustomObject]@{
                                            "value" = "$($storageAccountResourceGroupName)"
                                        }
                                        "storageAccountName"              = [PSCustomObject]@{
                                            "value" = "$($storageAccountName)"
                                        }
                                        "workspaceSubscriptionId"         = [PSCustomObject]@{
                                            "value" = "$($workspaceSubscriptionId)"
                                        }
                                        "workspaceResourceGroupName"      = [PSCustomObject]@{
                                            "value" = "$($workspaceResourceGroupName)"
                                        }
                                        "workspaceName"                   = [PSCustomObject]@{
                                            "value" = "$($workspaceName)"
                                        }
                                        "securityRules"                   = [PSCustomObject]@{
                                            "value" = $nsgSecurityRules
                                        }
                                    }
                                }
                            }
                            Else {
                                $nsgFileObject = [PSCustomObject]@{
                                    "`$schema"       = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
                                    "contentVersion" = "1.0.0.0"
                                    "parameters"     = [PSCustomObject]@{
                                        "vnetName"                        = [PSCustomObject]@{
                                            "value" = $vnetFullName
                                        }
                                        "subnetName"                      = [PSCustomObject]@{
                                            "value" = $subnetName
                                        }
                                        "enableFlowLogs"                  = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "enableTrafficAnalytics"          = [PSCustomObject]@{
                                            "value" = $true
                                        }
                                        "storageAccountResourceGroupName" = [PSCustomObject]@{
                                            "value" = "$($storageAccountResourceGroupName)"
                                        }
                                        "storageAccountName"              = [PSCustomObject]@{
                                            "value" = "$($storageAccountName)"
                                        }
                                        "workspaceResourceGroupName"      = [PSCustomObject]@{
                                            "value" = "$($workspaceResourceGroupName)"
                                        }
                                        "workspaceName"                   = [PSCustomObject]@{
                                            "value" = "$($workspaceName)"
                                        }
                                        "securityRules"                   = [PSCustomObject]@{
                                            "value" = $nsgSecurityRules
                                        }
                                    }
                                }
                            }

                            $fileName = "$($vnetFullName)-$($subnetName)-nsg.parameters.json"
                            $fileName
                            $fullFileName = "$($targetFileInfo.Directory.FullName)\$($fileName)"
                            If ([System.IO.File]::Exists($fullFileName)) {
                                If ($answer -ne "a") {
                                    $answer = Read-Host -Prompt "Overwrite file '$($fullFileName)' (y/a/n)"
                                }
                                If ($answer -eq 'y' -or $answer -eq "a") {
                                    [System.IO.File]::WriteAllText("$($fullFileName)", ($nsgFileObject | ConvertTo-Json -Depth 100))
                                }
                            }
                            Else {
                                [System.IO.File]::WriteAllText("$($fullFileName)", ($nsgFileObject | ConvertTo-Json -Depth 100))
                            }
                        }
                        Else {
                            Write-Warning "No NSG rules found for subnet $($subnetName)"
                        }
                    }
                    Else {
                        Write-Warning "No NSG table found for subnet $($subnetName)"
                    }
                }
                Else {
                    $i--
                    Break
                }
            }
        }
    }

    # Get the Json files in the Readme.md directory
    $targetFileInfo.DirectoryName
#    Invoke-Pester -Script @{ "Path" = "$($PSScriptRoot)\..\Tests\Network-Tests.ps1"; Parameters = @{ "ParameterPath" = $fileInfo.DirectoryName; Files = $null } }
}
Else {
    Write-Error "File '$($ReadmeFilePath)' not found"
}
