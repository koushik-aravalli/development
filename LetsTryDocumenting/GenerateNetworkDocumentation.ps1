<#
    PowerShell script to create Network solution Documentation using PowerShell Module PSDocs
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]

[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $true)]
    [String] $VirtualNetworkName,
    [Parameter (Mandatory = $true)]
    [String] $OutputPath,
    [Parameter (Mandatory = $true)]
    [String] $TemplatePath
)

#region
$null = Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name PSDocs -RequiredVersion 0.6.3 -Scope CurrentUser -Force
Import-Module PSDocs
#endregion

#region Get VirtualNetwork Information
$VirtualNetwork = Get-AzVirtualNetwork -Name $VirtualNetworkName
$subscription = Get-AzSubscription -SubscriptionId $VirtualNetwork.Id.Split('/')[2]
$resourceGroup = Get-AzResourceGroup -Name $VirtualNetwork.ResourceGroupName
$Subnets = [System.Collections.ArrayList]@()

Foreach ($subnet in $VirtualNetwork.Subnets) {
    $subnetObj = [PSCustomObject]@{
        subnetName    = $subnet.name
        addressSpace  = $subnet.AddressPrefix
        LoadBalancer  = $false
        DisableJITPIM = $false
        Nsg           = [PSCustomObject]@{
            SecurityRules = [System.Collections.ArrayList]@()
        }
    }

    If (!$subnet.NetworksecurityGroup) {
        $Subnets.Add($subnetObj) | out-null
        Continue
    }
    $nsg = Get-AzNetworkSecurityGroup -Name ($subnet.NetworksecurityGroup.Id.Split('/')[-1])

    Foreach ($securityRule in $nsg.DefaultSecurityRules) {
        $nsgRule = [PSCustomObject]@{
            Name           = $securityRule.Name
            Direction      = $securityRule.Direction
            Priority       = $securityRule.Priority
            Access         = $securityRule.Access
            'From address' = $securityRule.SourceAddressPrefix
            'To address'   = $securityRule.DestinationAddressPrefix
            'From port'    = $securityRule.SourcePortRange
            'To port'      = $securityRule.DestinationPortRange
        }
        $subnetObj.Nsg.SecurityRules.Add($nsgRule) | out-null
    }
    Foreach ($securityRule in $nsg.SecurityRules) {
        $nsgRule = [PSCustomObject]@{
            Name           = $securityRule.Name
            Direction      = $securityRule.Direction
            Priority       = $securityRule.Priority
            Access         = $securityRule.Access
            'From address' = $securityRule.SourceAddressPrefix
            'To address'   = $securityRule.DestinationAddressPrefix
            'From port'    = $securityRule.SourcePortRange
            'To port'      = $securityRule.DestinationPortRange
        }
        $subnetObj.Nsg.SecurityRules.Add($nsgRule) | out-null
    }

    $Subnets.Add($subnetObj) | out-null
}
$dnsOption = 'AzureADDSDNS'
$dns = @{
    "Name" = $dnsOption
}
#endregion

#region Get PrivateDNS If any
$privateDns = Get-AzPrivateDnsZone
$vnetLinkedPrivateDns = [System.Collections.ArrayList]@()
foreach ($pdns in $privateDns) {
    $dnsVnetlink = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $pdns.ResourceGroupName -ZoneName $pdns.Name
    If($dnsVnetlink.VirtualNetworkId -eq $VirtualNetwork.Id){
        $vnetLinkedPrivateDns.Add($pdns.ResourceId)
    }
}
#endregion

#region Build VirtualNetwork
$inputObject = [PSCustomObject]@{
    Environment        = [PSCustomObject]@{
        SubscriptionName  = $subscription.Name
        ResourceGroupName = $resourceGroup.Name
        Location          = $VirtualNetwork.Location
        Tags              = $resourceGroup.Tags
    }
    Subnet             = $Subnets
    GatewayType        = $null
    VirtualNetworkName = $VirtualNetwork.Name
    DNS                = $dns
    Peering = @($VirtualNetwork.VirtualNetworkPeerings.RemoteVirtualNetwork.Id)
    PrivateDns = $vnetLinkedPrivateDns
}
#endregion

# Configure MarkDown options
$options = New-PSDocumentOption -Option @{ 'Markdown.UseEdgePipes' = 'Always'; 'Markdown.ColumnPadding' = 'None' };

#region Build Readme Object
$Environment = [PSCustomObject]@{
    SubscriptionName= $inputObject.Environment.SubscriptionName
    Location        = $inputObject.Environment.Location
    AllowedLocation = 'westeurope, northeurope'
    Tags            = $inputObject.Environment.BusinessApplicationCI
}

$readmeObject = [pscustomobject]@{
    'Environment'        = $Environment
    'ResourceGroup'      = $inputObject.ResourceGroup
    'VirtualNetworkName' = $VirtualNetworkName
    'DNS'                = $($inputObject.DNS.Name)
    'Subnet'             = $inputObject.Subnet
    'RouteTableSection'  = ''
    'NsgSection'         = ''
    'Peering'            = $inputObject.Peering
    'PrivateDns'         = $inputObject.PrivateDns
}
#endregion

#region Generate Readme
$READMERouteTableTemplateName = 'RouteTable.doc.ps1'
Invoke-PSDocument -Path ('{0}\SubTemplates\{1}' -f $TemplatePath, $READMERouteTableTemplateName) -InputObject $readmeObject -OutputPath $OutputPath -Option $options;
$readmeObject.RouteTableSection = (Get-Content -Path "$OutputPath/README.md" -Encoding UTF8 -Raw).Replace('# ', '## ')

$READMENsgTemplateName = 'NetworkSecurityGroup.doc.ps1'
Invoke-PSDocument -Path ('{0}\SubTemplates\{1}' -f $TemplatePath, $READMENsgTemplateName) -InputObject $readmeObject -OutputPath $OutputPath -Option $options;
$readmeObject.NsgSection = (Get-Content -Path "$OutputPath/README.md" -Encoding UTF8 -Raw).Replace('# ', '## ')

$READMETemplateName = 'BaseTemplate.doc.ps1'

Invoke-PSDocument -Path ('{0}\{1}' -f $TemplatePath, $READMETemplateName) -InputObject $readmeObject -OutputPath $OutputPath -Option $options;

$Content = Get-Content -Path ('{0}\README.md' -f $OutputPath)
#Replace booleans (true) by 'X'
$Content = $Content -replace 'true', 'X'
#Replace boolean (false) with empty string
$Content = $Content -replace 'false', ' '
$Content | Set-Content -Path ('{0}\README.md' -f $OutputPath)  -Force
#endregion