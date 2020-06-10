<#
    PowerShell script to create VNet Markdown README file using PowerShell Module PSDocs

    More info can be found on WIKI: https://dev.azure.com/cbsp-abnamro/Azure/_wiki/wikis/Azure.wiki/5853/Self-Service-Networking-MVP1-IaaS-Pattern

    Install module using Install-Module PSDocs
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]

[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $true)]
    [String] $OutputPath,
    [Parameter (Mandatory = $true)]
    [String] $TemplatePath,
    [Parameter (Mandatory = $true)]
    [String] $InputObjectRaw
    )

#region 
Import-Module PSDocs
#endregion

$data = $InputObjectRaw | ConvertFrom-Json

#region Environment
$Environment = [PSCustomObject]@{
    SubscriptionName = $data.Environment.SubscriptionName.Replace("AABNL AZ ","") # Change to short subscriptionname
    ServiceName = $data.Environment.ServiceShortName
    Location = $data.Environment.Location
    AllowedLocation = 'westeurope, northeurope'
    BusinessApplicationCI = $data.Environment.BusinessApplicationCI
    BillingCode = $data.Environment.BillingCode
    Provider = $data.Environment.Provider
    AppName = $data.Environment.AppName
    CIA = $data.Environment.CIA
    ContactMail = $data.Environment.ContactMail
    ContactPhone = $data.Environment.ContactPhone
    EnvironmentType = $data.Environment.EnvironmentType 
}
#endregion

#region Subnet object
If ($data.NetworkType -eq 'IaaS') {
    $Subnet = [PSCustomObject]@{
        SubnetName = $data.VirtualNetworkInfo.SubnetName
        AddressSpace = $data.VirtualNetworkInfo.IPRange
    }
}
ElseIf ($data.NetworkType -eq 'ADB') {
    $Subnet = @( [PSCustomObject]@{
        SubnetName = $data.VirtualNetworkInfo.PrivateSubnetName
        AddressSpace = $data.VirtualNetworkInfo.PrivateIPRange
    },
    [PSCustomObject]@{
        SubnetName = $data.VirtualNetworkInfo.PublicSubnetName
        AddressSpace = $data.VirtualNetworkInfo.PublicIPRange
    })
}
#endregion

#region Delegation object

If ($data.NetworkType -eq 'IaaS') {
    $Delegation = [PSCustomObject]@{
        ResourceGroup =  @{
            'Name' = $data.Delegation.ResourceGroup.Name
            'ObjectId' = $data.Delegation.ResourceGroup.ObjectId
        }   
    SubnetJoin = @{
        SubnetName = $($Subnet.SubnetName)
        SPNName = $data.Delegation.SubnetJoin.SPNName
        ObjectId = $data.Delegation.SubnetJoin.ObjectId
        }
    }
}
ElseIf ($data.NetworkType -eq 'ADB') {
    $Delegation = [PSCustomObject]@{
        ResourceGroup =  @{
            'Name' = $data.Delegation.ResourceGroup.Name
            'ObjectId' = $data.Delegation.ResourceGroup.ObjectId
        }  
    SubnetJoin = @([PSCustomObject]@{
        SubnetName = $($data.VirtualNetworkInfo.PrivateSubnetName)
        SPNName = $data.Delegation.SubnetJoin.SPNName
        ObjectId = $data.Delegation.SubnetJoin.ObjectId
        },
        [PSCustomObject]@{
            SubnetName = $($data.VirtualNetworkInfo.PublicSubnetName)
            SPNName = $data.Delegation.SubnetJoin.SPNName
            ObjectId = $data.Delegation.SubnetJoin.ObjectId
        })
    }
}

#endregion

$InputObject = [pscustomobject]@{
    'VirtualNetworkName' = ($data.VirtualNetworkInfo.VirtualNetworkName).split('-')[0]
    'SolutionVersion' = 'x.x'
    'Environment' = $Environment
    'DNS' = $($data.DNS.Name)
    'Peering' = 'Hub/Spoke'
    'Subnet' =  $Subnet
    'Delegation' = $Delegation
}

If ($data.NetworkType -eq 'IaaS') {
    $InputObject | add-member -MemberType NoteProperty -Name 'LoadBalancer' -Value $($data.LoadBalancer)
}

# Configure MarkDown options
$options = New-PSDocumentOption -Option @{ 'Markdown.UseEdgePipes' = 'Always'; 'Markdown.ColumnPadding' = 'None'};

If ($data.NetworkType -eq 'IaaS') {
    $READMETemplateName = 'IaaS.README.doc.ps1'
}
ElseIf ($data.NetworkType -eq 'ADB') {
    $READMETemplateName = 'ADB.README.doc.ps1'
}

Invoke-PSDocument -Path ('{0}\{1}' -f $TemplatePath, $READMETemplateName) -InputObject $InputObject -OutputPath $OutputPath -Option $options;

#region Refactor README
$Content = Get-Content -Path ('{0}\README.md' -f $OutputPath) 
#Replace booleans (true) by 'X'
$Content = $Content -replace 'true', 'X'
#Replace boolean (false) with empty string
$Content = $Content -replace 'false', ' '
$Content | Set-Content -Path ('{0}\README.md' -f $OutputPath)  -Force
#endregion