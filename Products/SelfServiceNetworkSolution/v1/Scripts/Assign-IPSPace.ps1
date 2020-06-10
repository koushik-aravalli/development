<#
.DESCRIPTION
    This script will do an inventory of the Hub and Spoke networks and retrieves the IP Spaces of a gives set of IP ranges & updates a Wiki page.
    The script can also assign free IP Spaces based on the amount of IP addresses required.
    Required access:
        Wiki: Read & Write

.PARAMETER OrganizationName [String]
    The name of the Azure DevOps Orgnazation

.PARAMETER ProjectName [String]
    The name of the Azure DevOps project

.PARAMETER ERCircuitSubscriptionId [String]
    The subscription id of the subscription in which the ExpressRoute Circuit is deployed

.PARAMETER ERCircuitResourceGroupName [String]
    The Resource Group in which the Express Route Circuit is deployed

.PARAMETER ERCircuitName [String]
    The name of the ExpressRoute Circuit that will be used to retrieve the HUB VNet

.PARAMETER WikiPageName [String]
    The Wiki page that will be updated with the IPAM info

.PARAMETER Path [String]
    The Path to the Wiki page that will be updated with the IPAM info

.PARAMETER PersonalAccessToken [String]
    A AzureDevOps PersonalAccessToken from a NPA with the following access:
        Wiki: Read & Write

.PARAMETER RawInputObject [String]
    The InputObject data coming from the Azure Function containing RequiredIPAddresses, ServiceLongName, ServiceShortName, EnvironmentType and SubscriptionName info

.PARAMETER EnvironmentRGTags [String]
    The InputObject data coming from the Get-ResourceGroupTags script containing AppName and BusinessApplicationCI info

.EXAMPLE
    .\Assing-IPSPace.ps1 -RawInputObject '{"Environment":{"SubscriptionName":"AABNL AZ Engineering","ResourceGroupName":"nssd01-e-rg","ServiceShortName":"nssd","Location":"westeurope","ServiceLongName":"nssd01","EnvironmentType":"Engineering"},"Subnet":{"Size":"123"},"DNS":{"Name":"AzureADDSDNS"},"Delegation":{"SubnetJoin":{"SPNName":"nssd01-e-rg-spgroup","ObjectId":"fc028492-acc7-409f-8f70-98428c6160e2"},"ResourceGroup":{"Name":"nssd01-e-rg-devgroup","ObjectId":"7a131472-2e98-4fc2-ad51-703235c7f424"}},"HasLoadBalancer":false}' -EnvironmentRGTags '{"BillingCode":"NL47356","Provider":"CBSP Azure","AppName":"Self Service Stefan Stranger","ContactMail":"stefan.stranger@nl.abnamro.com","ContactPhone":"+31611309623","BusinessApplicationCI":"CI0010180","CIA":"333"}' -PersonalAccessToken '***'
#>

[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $false)][String] $OrganizationName = 'cbsp-abnamro',
    [Parameter (Mandatory = $false)][String] $ProjectName = 'Azure',
    [Parameter (Mandatory = $false)][String] $ERCircuitSubscriptionId = 'b658ffad-30c7-4be6-881c-e3dc1f6520af',
    [Parameter (Mandatory = $false)][String] $ERCircuitResourceGroupName = 'infra-expressroute-p-rg',
    [Parameter (Mandatory = $false)][String] $ERCircuitName = 'infra-p-vz-ams-01-cir',
    [Parameter (Mandatory = $false)][String] $WikiPageName = 'Self-Service Network Deployments - IPAM',
    [Parameter (Mandatory = $false)][String] $Path = '/Way of Working/Platform Team',
    [Parameter (Mandatory = $false)][String[]] $ReservedIPSpaces = @('10.232.205.0/24', '10.232.206.0/24', '10.232.207.0/24', '10.232.208.0/24', '10.232.209.0/24', '10.232.210.0/24', '10.232.211.0/24', '10.232.212.0/24', '10.232.213.0/24'),
    [Parameter (Mandatory = $true)][String] $PersonalAccessToken,
    [Parameter (Mandatory = $false)][String] $RawInputObject,
    [Parameter (Mandatory = $false)][String] $EnvironmentRGTags
)


$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Function Assign-IPRange {
    Param (
      [Parameter (Mandatory = $true)] $AvailableIPSpace,
      [Parameter (Mandatory = $true)] $SubnetSize,
      [Parameter (Mandatory = $true)] $VirtualNetworkName,
      [Parameter (Mandatory = $true)] $SubnetName,
      [Parameter (Mandatory = $true)] $Subscription,
      [Parameter (Mandatory = $true)] $ResourceGroupName,
      [Parameter (Mandatory = $true)] $ApplicationCI,
      [Parameter (Mandatory = $true)] $ApplicationName
    )
    $l = 1
    Do {
      $AvailableIPSpace | ForEach-Object {
        $subnet = $_.Split('/')
        If ($SubnetSize.SubString($SubnetSize.IndexOf('/') + 1) -eq $subnet[1]) {
          $tableItem = [PSCustomObject]@{
            "State"           = "In Use"
            "Network address" = "$_"
            "Virtual Network" = "$VirtualNetworkName"
            "Subnet"          = "$SubnetName"
            "Subscription"    = "$Subscription"
            "Resource Group"  = "$ResourceGroupName"
            "CI"              = "$ApplicationCI"
            "AppName"         = "$ApplicationName"
          }
          If ($tableItems.GetEnumerator() | Where-Object -FilterScript { $_.Key -eq $subnet[0] }) {
            $tableItems.Remove($subnet[0])
          }
          $tableItems.Add($subnet[0], $tableItem)
          $AvailableIPSpace = $AvailableIPSpace -ne $_
          $IPRange = $_
          $l++
        }
        If ($l -gt 1) { Break }
      }
      If ($l -eq 1) {
        $ipSpaceToUse = $AvailableIPSpace | Where-Object -FilterScript { $_.Substring($_.Length - 2) -eq 24 }
        If (![System.String]::IsNullOrWhiteSpace($ipSpaceToUse)) {
          $subnet = $ipSpaceToUse[0].Split('/')
          $bits = [System.String]::Join("", ($subnet[0].Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
          $newAddress = ($subnet[0] + "/" + ([Int32]$SubnetSize.SubString($SubnetSize.IndexOf('/') + 1)).ToString())
          If (!$subnetsToKeep.Contains($newAddress)) {
            $tableItem = [PSCustomObject]@{
              "State"           = "In Use"
              "Network address" = "$newAddress"
              "Virtual Network" = "$VirtualNetworkName"
              "Subnet"          = "$SubnetName"
              "Subscription"    = "$Subscription"
              "Resource Group"  = "$ResourceGroupName"
              "CI"              = "$ApplicationCI"
              "AppName"         = "$ApplicationName"
            }
            If ($tableItems.GetEnumerator() | Where-Object -FilterScript { $_.Key -eq $subnet[0] }) {
              $tableItems.Remove($subnet[0])
            }
            $AvailableIPSpace = $AvailableIPSpace | Where-Object -FilterScript { $_ -ne $ipSpaceToUse[0] }
            $tableItems.Add($subnet[0], $tableItem)
            $IPRange = $newAddress
            $l++
    
            $addressSpaceBits = [System.String]::Join("", ($subnet[0].Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
            $cidr = [System.Convert]::ToInt32($SubnetSize.SubString($SubnetSize.IndexOf('/') + 1))
            $subnetAddressSpace = $addressSpaceBits.Substring(0, $cidr)
    
            $k = 1
            Do {
              $nextNetworkAddress = [System.Convert]::ToInt32($subnetAddressSpace, 2) + $k
              $nextBinaryNetworkAddress = [System.Convert]::ToString($nextNetworkAddress, 2).PadLeft($cidr, '0').PadRight(32, '0')
              If ($nextBinaryNetworkAddress.Substring(24, 8) -eq '00000000') {
                Break
              }
              $newIPAddressArray = For ($j = 0; $j -lt 4; $j++) {
                [System.Convert]::ToInt64($nextBinaryNetworkAddress.Substring($j * 8, 8), 2)
              }
              $newIPAddress = [String]::Join('.', $newIPAddressArray)
              If (!$subnetsToKeep.Contains($newIPAddress) -and $newIPAddress -ne $subnet[0] -and $reservedIPSpace.Contains($newIPAddress.SubString(0, $newIPAddress.LastIndexOf('.')))) {
                $tableItem = [PSCustomObject]@{
                  "State"           = "Free"
                  "Network address" = "$($newIPAddress)/$($cidr)"
                  "Virtual Network" = ""
                  "Subnet"          = ""
                  "Subscription"    = ""
                  "Resource Group"  = ""
                  "CI"              = ""
                  "AppName"         = ""
                }
                $tableItems.Add($newIPAddress, $tableItem)
                $AvailableIPSpace = $AvailableIPSpace += "$($newIPAddress)/$($cidr)"
              }
              Else {
                Break
              }
              $k++
            }
            While ($nextBinaryNetworkAddress.Substring(24, 8) -ne '00000000')
          }                        
        }
      }
      Else {
        $exp = $PSItem.Exception.Message
        Write-Host "##vso[task.logissue type=error]$exp"
        Write-Error $PSItem.Exception.Message
      }
    }
    While ($l -eq 1)
    Return $VirtualNetworkName, $SubnetName, $IPRange, $AvailableIPSpace
}
  

## Convert RawInputObject to Json
If (![System.String]::IsNullOrWhiteSpace($RawInputObject)) {
    $data = $RawInputObject | ConvertFrom-Json

    $RequiredIPAddresses = $data.Subnet.Size
    $ServiceShortName = $data.Environment.ServiceShortName
    $ServiceLongName = $data.Environment.ServiceLongName
    $Environment = $data.Environment.EnvironmentType
    $Subscription = $data.Environment.SubscriptionName.Replace("AABNL AZ ","")
    $DeploymentType = $data.NetworkType

    Write-Host "Required IP Addresses: $($RequiredIPAddresses)"
    Write-Host "Service Shortname: $($ServiceShortName)"
    Write-Host "Service Longname: $($ServiceLongName)"
    Write-Host "Environment: $($Environment)"
    Write-Host "Subscription: $($Subscription)"
    Write-Host "DeploymentType: $($DeploymentType)"

    $inputParameters = [PSCustomObject]@{        
        'Required IP Addresses' = $RequiredIPAddresses;
        'ServiceShortName' = $ServiceShortName;
        'ServiceLongName' = $ServiceLongName;
        'Environment' = $Environment;
        'Subscription' = $Subscription; 
        'DeploymentType' = $DeploymentType; 
    }

    Foreach ($inputParam in $($inputParameters.PSobject.Properties))
    {
        If ([System.String]::IsNullOrWhiteSpace($inputParam.Value)) {
            $ErrorMessage = "Empty value $($inputParam.Name) found! Cannot continue"
            Write-Host "##vso[task.logissue type=error]$ErrorMessage"
            Write-Error $ErrorMessage
        }
    }
}
Else {
    Write-Warning -Message "RawInputObject parameter is not set"
}

## Convert EnvironmentRGTags input object to Json
If (![System.String]::IsNullOrWhiteSpace($EnvironmentRGTags)) {
    $rgTags = $EnvironmentRGTags | ConvertFrom-Json

    $ApplicationCI = $rgTags.BusinessApplicationCI
    $ApplicationName = $rgTags.AppName

    Write-Host "Business ApplicationCI: $($ApplicationCI)"
    Write-Host "AppName: $($ApplicationName)"

    $inputParameters = [PSCustomObject]@{        
        'Business ApplicationCI' = $ApplicationCI;
        'AppName' = $ApplicationName;
    }

    Foreach ($inputParam in $($inputParameters.PSobject.Properties))
    {
        If ([System.String]::IsNullOrWhiteSpace($inputParam.Value)) {
            $ErrorMessage = "Empty value $($inputParam.Name) found! Cannot continue"
            Write-Host "##vso[task.logissue type=error]$ErrorMessage"
            Write-Error $ErrorMessage
        }
    }
}
Else {
    Write-Warning -Message "EnvironmentRGTags parameter is not set"
}

[System.Void][System.Reflection.Assembly]::LoadWithPartialName("System.Web")

$accessToken = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$($PersonalAccessToken)")))"
$headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

# Get current state
Try {
    $allSubnets = [System.Collections.Specialized.ListDictionary]::new()
    $currentContent = ""
    $wikiPageDetails = $null
    $wikis = Invoke-RestMethod -Uri "https://dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/wiki/wikis?api-version=5.1" -Method Get -Headers $headers -UseBasicParsing
    $projectWiki = $wikis.value | Where-Object -FilterScript { $_.type -eq 'projectWiki' }
    $wikiPageRoot = Invoke-RestMethod -Uri "$($projectWiki.url)/pages?path=$([System.Web.HttpUtility]::UrlEncode($Path))&recursionLevel=full&api-version=5.1" -Method Get -Headers $headers -UseBasicParsing
    If ($wikiPage = ($wikiPageRoot.subPages | Where-Object -FilterScript { $_.path.EndsWith("/$($WikiPageName)") })) {
        # Page exists, check for reserved addresses
        $wikiPageDetailsRequest = Invoke-WebRequest -Uri "$($wikiPage.url)?includeContent=true&api-version=5.1" -Method Get -Headers $headers -UseBasicParsing
        $wikiPageDetails = $wikiPageDetailsRequest.Content | ConvertFrom-Json
        $currentContent = $wikiPageDetails.content
        $tableRegex = [System.Text.RegularExpressions.Regex]::new("^\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|(.*?)\|\n", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        If ($tableRegex.IsMatch($currentContent)) {
            $rows = $tableRegex.Matches($currentContent)
        }
    }
}
Catch {
    $exp = $PSItem.Exception.Message
    Write-Host "##vso[task.logissue type=error]$exp"
    Write-Error $PSItem.Exception.Message
}

    Try {
    $subscriptions = Get-AzSubscription
    $context = Get-AzContext
    $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new([Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile)
    $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
    $headersGraph = @{
        'Accept'        = 'application/json'
        'x-ms-version'  = '2014-06-01'
        'Authorization' = "Bearer $($token.AccessToken)"
        "Content-Type"  = 'application/json'
    }
    $subscriptionIds = $subscriptions | ForEach-Object { $_.Id }
    $uri = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2018-09-01-preview"

    $body = [PSCustomObject]@{
        "subscriptions" = @($SubscriptionIds)
        "query"         = "where type =~ 'Microsoft.Network/expressRouteCircuits' and tags['AppName'] =~ 'CBSP Azure Platform Services' | project name, location, subscriptionId, tags, properties, id"
        "options"       = [PSCustomObject]@{
            "`$top"  = 5000
            "`$skip" = 0
        }
    }
    $erCircuits = Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json -Compress -Depth 100) -Headers $headersGraph -UseBasicParsing
    $erCircuitColumns = $erCircuits.data.columns.name
    Write-Host "Found $($erCircuits.totalRecords) express Route Circuit(s)"

    $body = [PSCustomObject]@{
        "subscriptions" = @($SubscriptionIds)
        "query"         = "where type =~ 'Microsoft.Network/connections' and tags['AppName'] =~ 'CBSP Azure Platform Services' | project name, location, subscriptionId, tags, properties, id"
        "options"       = [PSCustomObject]@{
            "`$top"  = 5000
            "`$skip" = 0
        }
    }
    $erConnections = Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json -Compress -Depth 100) -Headers $headersGraph -UseBasicParsing
    $erConnectionColumns = $erConnections.data.columns.name
    Write-Host "Found $($erConnections.totalRecords) express Route Connection(s)"

    $body = [PSCustomObject]@{
        "subscriptions" = @($SubscriptionIds)
        "query"         = "where type =~ 'Microsoft.Network/virtualNetworkGateways' and tags['AppName'] =~ 'CBSP Azure Platform Services' | project name, location, subscriptionId, tags, properties, id"
        "options"       = [PSCustomObject]@{
            "`$top"  = 5000
            "`$skip" = 0
        }
    }
    $virtualNetworkGateways = Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json -Compress -Depth 100) -Headers $headersGraph -UseBasicParsing
    $virtualNetworkGatewayColumns = $virtualNetworkGateways.data.columns.name
    Write-Host "Found $($virtualNetworkGateways.totalRecords) Virtual Network Gateway(s)"

    $body = [PSCustomObject]@{
        "subscriptions" = @($SubscriptionIds)
        "query"         = "where type =~ 'Microsoft.Network/virtualNetworks' | project name, location, subscriptionId, tags, properties, id, resourceGroup"
        "options"       = [PSCustomObject]@{
            "`$top"  = 5000
            "`$skip" = 0
        }
    }
    $virtualNetworks = Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json -Compress -Depth 100) -Headers $headersGraph -UseBasicParsing
    $virtualNetworkColumns = $virtualNetworks.data.columns.name
    Write-Host "Found $($virtualNetworks.totalRecords) Virtual Network(s)"

    $iERCircuit = 1
    ForEach ($erCircuit In $erCircuits.data.rows) {
        Write-Host "Processing ExpressRout circuit $($iERCircuit)/$($erCircuits.totalRecords)"
        $iERCircuit++
        $iERConnection = 1
        $erConnectionRows = $erConnections.data.rows | Where-Object { $_[$erConnectionColumns.IndexOf('properties')].peer.id -eq $erCircuit[$erCircuitColumns.IndexOf('id')] }
        ForEach ($erConnection In $erConnectionRows) {
            Write-Host "  Processing ExpressRoute connection $($iERConnection)/$($erConnectionRows.Count)"
            $iERConnection++
            If ($erConnectionRows.Count -eq 6) {
                $virtualNetworkGateway = ($virtualNetworkGateways.data.rows | Where-Object -FilterScript { $_[$virtualNetworkGatewayColumns.IndexOf('id')] -eq $erConnectionRows[4].virtualNetworkGateway1.id})
            }
            Else {
                $virtualNetworkGateway = ($virtualNetworkGateways.data.rows | Where-Object -FilterScript { $_[$virtualNetworkGatewayColumns.IndexOf('id')] -eq $erConnection[$erConnectionColumns.IndexOf('properties')].virtualNetworkGateway1.id })
            }
                $iGateway = 1
                ForEach ($ipConfiguration In $virtualNetworkGateway[$virtualNetworkGatewayColumns.IndexOf('properties')].ipConfigurations) {
                    Write-Host "    Processing Virtual Network Gateway $($iGateway)/$($virtualNetworkGateway[4].ipConfigurations.Count)"
                    $iGateway++
                    $resourceIdItems = $ipConfiguration.properties.subnet.id.Split('/')
                    # Process hub network
                    $infarVnetResourceId = [String]::Join('/', $resourceIdItems, 0, $resourceIdItems.Count - 2)
                    $infraVnet = $virtualNetworks.data.rows | Where-Object -FilterScript { $_[$virtualNetworkColumns.IndexOf('id')] -eq $infarVnetResourceId }
                    Write-Host "      $($infraVnet[$virtualNetworkColumns.IndexOf('name')])"
                    $businessApplicationCI = ""
                    $appName = ""
                    If ($null -ne $infraVnet[$virtualNetworkColumns.IndexOf('tags')]) {
                        $tags = $infraVnet[$virtualNetworkColumns.IndexOf('tags')]
                        If ($null -ne ($tags | Get-Member -MemberType NoteProperty -Name 'Business Application CI')) {
                            $businessApplicationCI = $tags.'Business Application CI'
                        }
                        If ($null -ne ($tags | Get-Member -MemberType NoteProperty -Name 'AppName')) {
                            $appName = $tags.'AppName'
                        }
                    }
                    For ($i = 0; $i -lt $infraVnet[$virtualNetworkColumns.IndexOf('properties')].addressSpace.addressPrefixes.Count; $i++) {
                        $j = $infraVnet[$virtualNetworkColumns.IndexOf('properties')].subnets.properties.addressPrefix.IndexOf($infraVnet[$virtualNetworkColumns.IndexOf('properties')].addressSpace.addressPrefixes[$i])
                        If ($j -ge 0) {
                            $subnetKey = $infraVnet[$virtualNetworkColumns.IndexOf('properties')].addressSpace.addressPrefixes[$i].Split('/')[0]
                            $item = [PSCustomObject]@{
                                "subscriptionId"        = $infraVnet[$virtualNetworkColumns.IndexOf('subscriptionId')]
                                "resourceGroup"         = $infraVnet[$virtualNetworkColumns.IndexOf('resourceGroup')]
                                "businessApplicationCI" = $businessApplicationCI
                                "appName"               = $appName
                                "vnetName"              = "**$($infraVnet[$virtualNetworkColumns.IndexOf('name')])**"
                                "subnetName"            = $infraVnet[$virtualNetworkColumns.IndexOf('properties')].subnets[$j].name
                                "subnetAddressPrefix"   = $infraVnet[$virtualNetworkColumns.IndexOf('properties')].addressSpace.addressPrefixes[$i]
                            }
                            If (!$allSubnets.Contains($subnetKey)) {
                                $allSubnets.Add($subnetKey, $item)
                            }
                            Else {
                                $allSubnets.Item($subnetKey) = $item
                            }
                        }
                    }
                    # Process peerings
                    $virtualNetworkPeerings = $infraVnet[$virtualNetworkColumns.IndexOf('properties')].virtualNetworkPeerings | Where-Object -FilterScript { $_.properties.useRemoteGateways -eq $false}
                    $virtualNetworkPeerings
                    If ($infraVnet[$virtualNetworkColumns.IndexOf('name')] -ne 'hubwe08-p-vnet') {
                        If ($infraVnet[$virtualNetworkColumns.IndexOf('name')] -ne 'hubwe09-e-vnet') {
                            For ($i = 0; $i -lt $virtualNetworkPeerings.Count; $i++) {
                                $peering = $virtualNetworkPeerings[$i]
                                Write-Host "        Peering $($i + 1)/$($virtualNetworkPeerings.Count) - $($peering.name)"
                                If ($peering.properties.peeringState -ne 'Disconnected') {
                                    If ($peeringItem = ($virtualNetworks.data.rows | Where-Object -FilterScript { $_[$virtualNetworkColumns.IndexOf('id')] -eq $peering.properties.remoteVirtualNetwork.id })) {
                                        $businessApplicationCI = ""
                                        $appName = ""
                                        If ($null -ne $peeringItem[3]) {
                                            $tags = $peeringItem[3]
                                            If ($null -ne ($tags | Get-Member -MemberType NoteProperty -Name 'Business Application CI')) {
                                                $businessApplicationCI = $tags."Business Application CI"
                                            }
                                            If ($null -ne ($tags | Get-Member -MemberType NoteProperty -Name 'AppName')) {
                                                $appName = $tags.'AppName'
                                            }
                                        }

                                        For ($j = 0; $j -lt $peeringItem[4].addressSpace.addressPrefixes.Count; $j++) {
                                            $k = $peeringItem[4].subnets.properties.addressPrefix.IndexOf($peeringItem[4].addressSpace.addressPrefixes[$j])
                                            If ($k -ge 0) {
                                                $subnetKey = $peeringItem[4].addressSpace.addressPrefixes[$j].Split('/')[0]
                                                $item = [PSCustomObject]@{
                                                    "subscriptionId"        = $peeringItem[2]
                                                    "resourceGroup"         = $peeringItem[6]
                                                    "businessApplicationCI" = $businessApplicationCI
                                                    "appName"               = $appName
                                                    "vnetName"              = $peeringItem[0]
                                                    "subnetName"            = $peeringItem[4].subnets[$k].name
                                                    "subnetAddressPrefix"   = $peeringItem[4].addressSpace.addressPrefixes[$j]
                                                }
                                                If (!$allSubnets.Contains($subnetKey)) {
                                                    $allSubnets.Add($subnetKey, $item)
                                                }
                                                Else {
                                                    $allSubnets.Item($subnetKey) = $item
                                                }
                                            }
                                            Else {
                                                $subnetKey = $peeringItem[4].addressSpace.addressPrefixes[$j].Split('/')[0]
                                                $item = [PSCustomObject]@{
                                                    "subscriptionId"        = $peeringItem[2]
                                                    "resourceGroup"         = $peeringItem[6]
                                                    "businessApplicationCI" = $businessApplicationCI
                                                    "appName"               = $appName
                                                    "vnetName"              = $peeringItem[0]
                                                    "subnetName"            = ""
                                                    "subnetAddressPrefix"   = $peeringItem[4].addressSpace.addressPrefixes[$j]
                                                }
                                                If (!$allSubnets.Contains($subnetKey)) {
                                                    $allSubnets.Add($subnetKey, $item)
                                                }
                                                Else {
                                                    $allSubnets.Item($subnetKey) = $item
                                                }
                                            }
                                        }
                                    }
                                    Else {
                                        Write-Host "          Virtual Network '$($peering.properties.remoteVirtualNetwork.id)' not found" -ForegroundColor Yellow
                                    }
                                }
                                Else {
                                    Write-Host "          Peering to '$($peering.properties.remoteVirtualNetwork.id)' has the status '$($peering.properties.peeringState)'" -ForegroundColor Yellow
                                }
                            
                            }
                    }
                }
            }
        }
    }
}
Catch {
    $exp = $PSItem.Exception.Message
    Write-Host "##vso[task.logissue type=error]$exp"
    Write-Error $PSItem.Exception.Message
}

#Filter out the IP spaces in use by the Self-Service Network Deployment product
$availableIPSpace = @()
$subnetsToKeep = [System.Collections.Specialized.ListDictionary]::new()
If ($ReservedIPSpaces) {
    $availableIPs = @()
    $availableIPs = [System.Collections.ArrayList]$availableIPs
    Write-Host "Filtering out IP spaces"
    ForEach ($ipSpace in $ReservedIPSpaces) {
        $availableIPs.Add($ipSpace)
        $reservedIPSpace = $ipSpace.SubString(0, $ipSpace.LastIndexOf('.'))
        $allSubnets.GetEnumerator() | ForEach-Object {
            $subnet = $_
            $subnetPrefix = $subnet.Key.SubString(0, $subnet.Key.LastIndexOf('.'))
            If ($subnetPrefix -eq $reservedIPSpace) {
                $duplicate = ($subnetsToKeep.GetEnumerator() | Where-Object -FilterScript {$_.Key -ne $null -and $_.Key -eq $subnet.Key } | Group-Object)
                If(!$duplicate){
                    $subnetsToKeep.Add($subnet.Key, $subnet.Value)
                }
                Else {
                }
            }
        }
        $subnetsToKeep.GetEnumerator() | ForEach-Object {
            $subnet = $_
            $subnetPrefix = $subnet.Key.SubString(0, $subnet.Key.LastIndexOf('.'))
            If ($subnetPrefix -eq $reservedIPSpace) {
                $availableIPs.Remove($ipSpace)
            }
        }
    }
    $availableIPs = $availableIPs | select -Unique
    $availableIPSpace = $availableIPs | Where-Object -FilterScript {$_.Contains("/")}
    $reservedIPSpace = @()
    $ReservedIPSpaces | ForEach-Object {
        $reservedIPSpace += $_.SubString(0, $_.LastIndexOf('.'))
    }
    If ([System.String]::IsNullOrWhiteSpace($availableIPSpace)) {
        $exp = 'No IP Space available'
        Write-Host "##vso[task.logissue type=error]$exp"
        Write-Error $exp

    }
}

# Create table
Write-Host "Find free address ranges"
$tableItems = [System.Collections.Specialized.ListDictionary]::new()
# Fill new table with items
$subnetsToKeep.Keys | ForEach-Object { [Version]$_ } | Sort-Object | ForEach-Object {
    $versionItem = $_
    $subnetAddressPrefix = $versionItem.ToString()
    $item = $subnetsToKeep.Item($subnetAddressPrefix)
    $subnetAddressSuffix = $item.subnetAddressPrefix.Split('/')[1]
    $subscriptionName = ""
    If ($subscriptions.Id.IndexOf($item.subscriptionId) -ge 0) {
        $subscriptionName = $subscriptions.Name[$subscriptions.Id.IndexOf($item.subscriptionId)].Replace("AABNL AZ ", "")
    }
    If ($item.subnetName.Length -eq 0) {
        $tableItem = [PSCustomObject]@{
            "State"           = "Reserved"
            "Network address" = $item.subnetAddressPrefix
            "Virtual Network" = $item.vnetName
            "Subnet"          = $item.subnetName
            "Subscription"    = $subscriptionName
            "Resource Group"  = $item.resourceGroup
            "CI"              = $item.businessApplicationCI
            "AppName"         = $item.appName
        }
        $tableItems.Add($subnetAddressPrefix, $tableItem)
    }
    Else {
        $tableItem = [PSCustomObject]@{
            "State"           = "In use"
            "Network address" = $item.subnetAddressPrefix
            "Virtual Network" = $item.vnetName
            "Subnet"          = $item.subnetName
            "Subscription"    = $subscriptionName
            "Resource Group"  = $item.resourceGroup
            "CI"              = $item.businessApplicationCI
            "AppName"         = $item.appName
        }
        $tableItems.Add($subnetAddressPrefix, $tableItem)
    }
    If ($subnetAddressSuffix -eq 23) {
        $newVersionItem = [Version]::new($versionItem.Major, $versionItem.Minor, $versionItem.Build + 2, $versionItem.Revision)
        If (!$subnetsToKeep.Contains($newVersionItem.ToString())) {
            $tableItem = [PSCustomObject]@{
                "State"           = "Free"
                "Network address" = "$($newVersionItem.ToString())/24"
                "Virtual Network" = ""
                "Subnet"          = ""
                "Subscription"    = ""
                "Resource Group"  = ""
                "CI"              = ""
                "AppName"         = ""
            }
            $tableItems.Add($newVersionItem.ToString(), $tableItem)
            $availableIPSpace += $tableItem.'Network address'
        }
    }
    ElseIf ($subnetAddressSuffix -eq 24) {
        $newVersionItem = [Version]::new($versionItem.Major, $versionItem.Minor, $versionItem.Build + 1, $versionItem.Revision)
        If (!$subnetsToKeep.Contains($newVersionItem.ToString()) -and $reservedIPSpace.Contains($newVersionItem.ToString().SubString(0, $newVersionItem.ToString().LastIndexOf('.')))) {
            $tableItem = [PSCustomObject]@{
                "State"           = "Free"
                "Network address" = "$($newVersionItem.ToString())/24"
                "Virtual Network" = ""
                "Subnet"          = ""
                "Subscription"    = ""
                "Resource Group"  = ""
                "CI"              = ""
                "AppName"         = ""
            }
            $tableItems.Add($newVersionItem.ToString(), $tableItem)
            $availableIPSpace += $tableItem.'Network address'
        }
    }
    ElseIf ($subnetAddressSuffix -gt 24) {
        $addressSpaceBits = [System.String]::Join("", ($subnetAddressPrefix.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }))
        $cidr = [System.Convert]::ToInt32($subnetAddressSuffix)
        $subnetAddressSpace = $addressSpaceBits.Substring(0, $cidr)

        $k = 1
        Do {
            $nextNetworkAddress = [System.Convert]::ToInt32($subnetAddressSpace, 2) + $k
            $nextBinaryNetworkAddress = [System.Convert]::ToString($nextNetworkAddress, 2).PadLeft($cidr, '0').PadRight(32, '0')
            If ($nextBinaryNetworkAddress.Substring(24, 8) -eq '00000000') {
                $subnetAddressSuffix = 24
            }
            $newIPAddressArray = For ($j = 0; $j -lt 4; $j++) {
                [System.Convert]::ToInt64($nextBinaryNetworkAddress.Substring($j * 8, 8), 2)
            }
            $newIPAddress = [String]::Join('.', $newIPAddressArray)
            If (!($subnetsToKeep.Contains($newIPAddress)) -and !($availableIPSpace.Contains("$($newIPAddress)/$($subnetAddressSuffix)")) -and $reservedIPSpace.Contains($newIPAddress.SubString(0, $newIPAddress.LastIndexOf('.')))) {
                $tableItem = [PSCustomObject]@{
                    "State"           = "Free"
                    "Network address" = "$($newIPAddress)/$($subnetAddressSuffix)"
                    "Virtual Network" = ""
                    "Subnet"          = ""
                    "Subscription"    = ""
                    "Resource Group"  = ""
                    "CI"              = ""
                    "AppName"         = ""
                }
                $tableItems.Add($newIPAddress, $tableItem)
                $availableIPSpace += $tableItem.'Network address'
            }
            Else {
                Break
            }
            $k++
        }
        While ($nextBinaryNetworkAddress.Substring(24, 8) -ne '00000000')
    }
}

#Assigning available IP space
$availableIPSpace | ForEach-Object {
    If ($_.SubString($_.IndexOf('/')+1) -eq 24) {
        $tableItem = [PSCustomObject]@{
        "State"           = "Free"
        "Network address" = "$_"
        "Virtual Network" = ""
        "Subnet"          = ""
        "Subscription"    = ""
        "Resource Group"  = ""
        "CI"              = ""
        "AppName"         = ""
        }
        $tableItems.Add($_.SubString(0, $_.LastIndexOf('/')), $tableItem)
    }
}


If (![System.String]::IsNullOrWhiteSpace($RawInputObject)) {
    If (![System.String]::IsNullOrWhiteSpace($EnvironmentRGTags)) {
        $subnetSize = @{
            '3'= '/29';
            '11'= '/28';
            '27' = '/27';
            '59' = '/26';
            '123' = '/25';
            '251' = '/24';
        }
        If ($DeploymentType -eq 'IaaS') {
            $subnetNames = @{
                'Engineering' = 'eng01-subnet';
                'Development' = 'dev01-subnet';
                'Test' = 'tst01-subnet';
                'Acceptance' = 'acc01-subnet';
                'Prodcuction' = 'prd01-subnet';
            }
        }
        ElseIf ($DeploymentType -eq 'ADB') {
            $subnetNames = @{
                'Public' = 'adbpublic01-subnet';
                'Private' = 'adbprivate01-subnet';
            }
        }
        $subscriptionRegEx = [Text.RegularExpressions.Regex]::new("Engineering|Management|VDC1|(?i)^(VDC)(?:[1-9][0-9]|[2-9]S$)")
        If ($subscriptionRegEx.Matches($Subscription)) {
            # Generate VNetName, SubnetName and RGName
            $environmentNumber =  $Environment.SubString(0,1).ToLower()
            If ($DeploymentType -eq 'IaaS') {
                $subnetNames.GetEnumerator() | ForEach-Object {
                    If ($_.Key -eq $Environment){
                        $subnetName = $_.Value
                    }
                }
            }
            ElseIf ($DeploymentType -eq 'ADB'){
                $subnetNamePublic = $($subnetNames.Values)[0]
                $subnetNamePrivate = $($subnetNames.Values)[1]
            }
            $vnetName = "$($ServiceLongName)-$($environmentNumber)-vnet"
            $rgName = "$($ServiceShortName)-vnets-$($environmentNumber)-rg"
            If ($vnetName -in $allSubnets.Values.vnetName) {
                $existingVNets = ($allSubnets.GetEnumerator() | Where-Object -FilterScript { ($_.Value.vnetName -replace "[!0-9]" , '') -eq ($vnetName -replace "[!0-9]" , '')}).Value.vnetName
                $sequenceNumber = $existingVNets | ForEach-Object { $_ -replace "[^0-9]" , ''}
                $nextSequenceNumber = "{0:00}" -f (($sequenceNumber | measure -Maximum).Maximum +1 )
                $vnetName = "$($ServiceLongName -replace "[!0-9]" , '')$nextSequenceNumber-$($environmentNumber)-vnet"
            } 
            $subnetSize.GetEnumerator() | ForEach-Object {
                If ($_.Key -eq $RequiredIPAddresses) {
                    $requiredSubnetSize = $_.Value
                }
            }

            Switch ($DeploymentType) {
                'Iaas' {
                    Write-Host "Assigning IP space to subnet $($subnetName) with Subnet Size $($requiredSubnetSize) in Virtual Network $($vnetName) in Resource Group $($rgName)"
                    $output = Assign-IPRange -AvailableIPSpace $availableIPSpace -SubnetSize $requiredSubnetSize -VirtualNetworkName $vnetName -SubnetName $subnetName -Subscription $Subscription -ResourceGroupName $rgName -ApplicationCI $ApplicationCI -ApplicationName $AppName
                    $vnetInfo = @{
                        "VirtualNetworkName" = $output[0];
                        "SubnetName"         = $output[1];
                        "IPRange"            = $output[2];
                        "VnetResourceGroup"  = $rgName;
                    } | ConvertTo-Json -Compress
                    Write-Host "Output variable VirtualNetwork Information: $($vnetInfo)"
                    Write-Host "##vso[task.setvariable variable=VirtualNetworkInfo;isOutput=true]$($vnetInfo)"
                }
                'ADB' {
                    Write-Host "Assigning IP space to subnets $($subnetNamePrivate) & $($subnetNamePublic) with Subnet Size $($requiredSubnetSize) in Virtual Network $($vnetName) in Resource Group $($rgName)"
                    #Assigning IPSpace for the ADB Private Subnet
                    $privateOutput = Assign-IPRange -AvailableIPSpace $availableIPSpace -SubnetSize $requiredSubnetSize -VirtualNetworkName $vnetName -SubnetName $subnetNamePrivate -Subscription $Subscription -ResourceGroupName $rgName -ApplicationCI $ApplicationCI -ApplicationName $AppName
                    $availableIPSpace = $privateOutput | Where-Object { $_ -ne $privateOutput[0] -and $_ -ne $privateOutput[1] -and $_ -ne $privateOutput[2]}
                    #Assigning IPSpace for the ADB Public Subnet
                    $publicOutput = Assign-IPRange -AvailableIPSpace $availableIPSpace -SubnetSize $requiredSubnetSize -VirtualNetworkName $vnetName -SubnetName $subnetNamePublic -Subscription $Subscription -ResourceGroupName $rgName -ApplicationCI $ApplicationCI -ApplicationName $AppName
                    $vnetInfo = @{
                        "VirtualNetworkName" = $privateOutput[0];
                        "PrivateSubnetName"  = $privateOutput[1];
                        "PrivateIPRange"     = $privateOutput[2];
                        "PublicSubnetName"   = $PublicOutput[1];
                        "PublicIPRange"      = $PublicOutput[2];
                        "VnetResourceGroup"  = $rgName;
                    } | ConvertTo-Json -Compress
                    Write-Host "Output variable VirtualNetwork Information: $($vnetInfo)"
                    Write-Host "##vso[task.setvariable variable=VirtualNetworkInfo;isOutput=true]$($vnetInfo)"


                }
            }
        }
        Else {
            $exp = $PSItem.Exception.Message
            Write-Host "##vso[task.logissue type=error]$exp"
            Write-Error $PSItem.Exception.Message
        }
    }
}

# Create example table
Write-Host "Create example table"
$ipAddress = "10.232.0.0"
$lines = @("# IPAM", "",
    "This pase currently has the status: **Draft**",
    "## Azure IP Plan principles",
    "",
    "- /16 assigned for Azure usage.",
    "- A small part of this IP space is 'pre-reserved' for the deployment of VNets & subnets using the Self-Service Network Delpoyment product",
    "- The table below shows the status of the 'pre-reserved' IP ranges (In Use, Free, Reserved)",
    "- Every time a Virtual Network is created or updated using the Self-Service Network Deployment product, a 'pre-reserved' IP space will be assigned to the subnet(s). It depends on the network requirements which size the subnet(s) will have",
    "- REMARK: *the table below is currently showing IP ranges that are **NOT** reserved for the Self-Service Network Deployments. The table is currently only used for testing purposes",
    "- REMARK: *the first 3 IP addresses of each subnet are in use for Azure routing and cannot be used for other IaaS purposes (NICs etc).*",
    "",
    "**Pre-Reserved IP Space**",
    "$($ReservedIPSpaces)"
    "## Example address ranges",
    "",
    "|Address space|Subnet mask|Start address|End address|Available IPs|", "|-|-|-|-|-|")
For ($cidr = 29; $cidr -ge 22; $cidr--) {
    # Subnetmask
    $binaryNetworkAddress = ("").PadLeft($cidr, '1').PadRight(32, '0')
    $subnetMaskArray = For ($j = 0; $j -lt 4; $j++) {
        [System.Convert]::ToInt64($binaryNetworkAddress.Substring($j * 8, 8), 2)
    }
    $subnetMask = [String]::Join('.', $subnetMaskArray)
    # Start IP address
    $startAddressInt = [System.Convert]::ToInt64([System.String]::Join("", ($ipAddress.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') })), 2) + 3
    $startAddressBinary = [System.Convert]::ToString($startAddressInt, 2).PadLeft(32, '0')
    $startAddressArray = For ($j = 0; $j -lt 4; $j++) {
        [System.Convert]::ToInt64($startAddressBinary.Substring($j * 8, 8), 2)
    }
    $startAddress = [String]::Join('.', $startAddressArray)
    # End IP address
    $endAddressInt = [System.Convert]::ToInt64([System.String]::Join("", ($ipAddress.Split('.') | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') })), 2) + [System.Convert]::ToInt64(("").PadLeft(32 - $cidr, "1"), 2) - 1
    $endAddressBinary = [System.Convert]::ToString($endAddressInt, 2).PadLeft(32, '0')
    $endAddressArray = For ($j = 0; $j -lt 4; $j++) {
        [System.Convert]::ToInt64($endAddressBinary.Substring($j * 8, 8), 2)
    }
    $endAddress = [String]::Join('.', $endAddressArray)
    # Available IP addresses
    $availableIPs = $endAddressInt - $startAddressInt

    # Add example line
    $lines += "|$($ipAddress)/$($cidr)|$($subnetMask)|$($startAddress)|$($endAddress)|$($availableIPs)|"
}

# Create text
Write-Host "Create IPAM table"
$lines += @("", "## $($WikiPageName)", "", "|State|Network address|Virtual Network|Subnet|Subscription|Resource Group|CI|AppName|", "|-|-|-|-|-|-|-|-|")
$lines += $tableItems.Keys | ForEach-Object { [Version]$_ } | Sort-Object | ForEach-Object {
    $versionItem = $_
    $subnetAddressPrefix = $versionItem.ToString()
    $item = $tableItems.Item($subnetAddressPrefix)
    Write-Output "|$($item.State)|$($item.'Network address')|$($item.'Virtual Network')|$($item.Subnet)|$($item.Subscription)|$($item.'Resource Group')|$($item.CI)|$($item.AppName)|"
}
$lines += ""
#[String]::Join([Environment]::NewLine, $lines)

#$newContent = [String]::Join([Environment]::NewLine, $lines)
$newContent = [String]::Join("`n", $lines)
#$currentContent

If ($currentContent -ne $newContent -and $newContent.Length -gt 1000) {
    Write-Host "Create/update wiki page from length $($currentContent.Length) to $($newContent.Length)"
    Write-Host ""
    $uri = "$($projectWiki.url)/pages?path=$([System.Web.HttpUtility]::UrlEncode("$($Path)/$($WikiPageName)"))&comment=$([System.Web.HttpUtility]::UrlEncode("Update IPAM for $($WikiPageName) with new contents."))&api-version=5.1"
    $body = [PSCustomObject]@{
        "content" = $newContent
    }

    $webRequest = [System.Net.WebRequest]::Create($uri)
    $webRequest.Headers.Add("Authorization", $accessToken)
    $webRequest.ContentType = 'application/json'
    $webRequest.Method = "PUT"

    If ($null -ne $wikiPageDetails) {
        Write-Host "  Add update header $($wikiPageDetailsRequest.Headers.Item('ETag')[0])"
        $headers.Add("If-Match", $wikiPageDetailsRequest.Headers.Item('ETag')[0])
        $webRequest.Headers.Add("If-Match", $wikiPageDetailsRequest.Headers.Item('ETag')[0])
    }

    Write-Host "Conver to bytes"
    $bytes = [System.Text.UTF8Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 100 -Compress))
    Write-Host "Add content length"
    $webRequest.ContentLength = $bytes.Length
    Write-Host "Get request stream"
    $dataStream = $webRequest.GetRequestStream()
    Write-Host "Send bytes"
    $dataStream.Write($bytes, 0, $bytes.Length)
    Write-Host "Close stream"
    $dataStream.Close()
    $webRequest | Get-Member
    Write-Host "Get response" # System.Net.WebResponse
    $response = $webRequest.GetResponse()
    Write-Host "Show status description"
    Try {
        $responseDetails = [System.Net.HttpWebResponse]$response
        $responseDetails.StatusCode # Created
        $responseDetails.StatusDescription # Created
    }
    Catch {
        Write-Host $_.Message
    }
    Write-Host "Get response stream"
    $responseStream = $response.GetResponseStream()
    Write-Host "Read stream"
    [System.IO.StreamReader]::new($responseStream).ReadToEnd()
    $response.Close()
    
    <#
    $result = Invoke-WebRequest -Uri $uri -Method Put -Body ($body | ConvertTo-Json -Depth 100 -Compress) -Headers $headers -UseBasicParsing
    If ($result.StatusCode -eq 200) {
        Write-Host "  Updated the wiki page"
    }
    ElseIf ($result.StatusCode -eq 201) {
        Write-Host "  Created wiki page"
    }
    Else {
        Write-Host "  Result status $($result.StatusCode)"
    }
    $result
    $body
    $result.Content | ConvertFrom-Json | ConvertTo-Json -Depth 100
    #>
} 
Else {
    Write-Host "No update"
}