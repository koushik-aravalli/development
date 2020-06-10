$SubscriptionNames = 'AABNL AZ VDC2S','AABNL AZ VDC3S','AABNL AZ VDC6S'
$IaaSPattern = '(dev|tst|acc|prd|frontend|app|vstsagents)[0-9][0-9]-subnet'

$xlfile = ".\Inventory.xlsx"
function clean{
    Remove-Item $xlfile -ErrorAction SilentlyContinue
}

function Test-Excel{

    $inventory = New-Object -TypeName "System.Collections.ArrayList"
    $cars="honda","toyota","ford","nissan"
    $bikes="yamaha","ducati","honda"
    $inventory.Add($cars)
    $inventory.Add($bikes)

    $xls = $inventory | Export-Excel -path $xlfile -WorkSheetname Inventory-VNET-$SubscriptionName -TableName NSG -AutoSize -PassThru -Show
    $xls.Workbook.styles.NamedStyles[0].Style.WrapText = $true 
    $xls.Save()
}

Function Get-NsgData{
    Param(
        [Parameter (Mandatory = $true)]
        [object[]]
        $NsgResourceId,
        [Parameter (Mandatory = $false)]
        [int]
        $vnetCount=20
    )

    $idx=1
    Foreach($nsgId in $NsgResourceId){
        $inventory = New-Object -TypeName "System.Collections.ArrayList"
        $nsg = Get-AzNetworkSecurityGroup -Name $nsgId.Split('/')[-1]

        #$inventory.Add($nsgMap) | Out-Null
        $inventory.Add($nsg.Name)
        $inventory.Add($nsg.SecurityRules.Name)
        $xls = $inventory | Export-Excel -path $xlfile -WorkSheetname Inventory-NSG-$SubscriptionName -TableName $nsg.Name -StartColumn $idx -AutoSize -PassThru
        $xls.Save()
        $idx++
    }

}

Function Get-VnetData{
    Param(
        [Parameter (Mandatory = $true)][String] $SubscriptionName
    )

    Select-AzSubscription -SubscriptionName $SubscriptionName
    
    # Get all Virtual Network 
    $vnets = Get-AzVirtualNetwork | Where-Object -FilterScript {$_.Subnets.Name -match $IaaSPattern}
    Write-Host "VNETs matched for IaaS $($vnets.Count)"

    $inventory = New-Object -TypeName "System.Collections.ArrayList"
    $nsgResourceIds = New-Object -TypeName "System.Collections.ArrayList"

    ForEach ($vnet in $vnets){
        $vnetMap = @{}
    
        $tags = (Get-AzResourceGroup -Name $vnet.ResourceGroupName).Tags
    
        # Get Res    
        $EnvironmentDetails  = @{
            SubscriptionName      = $SubscriptionName
            VNetName              = $vnet.Name
            ResourceGroupName     = $vnet.ResourceGroupName
            Location              = $vnet.Location
            Tags                  = $tags
        }
    
        $vnetMap.Add("EnvironmentDetails", $EnvironmentDetails)
    
        $VirtualNetwork = @{
            AddressSpace = $vnet.AddressSpace.AddressPrefixes
            DNS          = $vnet.DhcpOptions.DnsServersText
            Subnet       = $vnet.Subnets `
            | Where-Object -FilterScript {$_.Name -match $IaaSPattern} `
            | Select-Object -Property Name,AddressPrefix,@{n='Service';e={$_.ServiceEndpoints.Service}}, `
                                                         @{n='RT';e={(Get-AzRouteTable -Name $_.RouteTable.Id.Split('/')[-1]).Routes.NextHopIpAddress | out-string}}
        }
        $vnetMap.Add("VirtualNetwork",$VirtualNetwork)
        
        $Peering = @{
            Hub    = ($vnet.VirtualNetworkPeerings | Where-Object -FilterScript {$_.AllowForwardedTraffic -eq $true} | Select-Object -ExpandProperty RemoteVirtualNetwork | Select-Object -Property Id)#.Id.split('/')[-1]
            Spokes = ($vnet.VirtualNetworkPeerings | Where-Object -FilterScript {$_.AllowForwardedTraffic -eq $false} | Select-Object -ExpandProperty RemoteVirtualNetwork | Select-Object -Property Id)#.Id#.split('/')[-1]
        }
        $vnetMap.Add("Peering", $Peering)
    
        Write-Host "Adding data for $($vnetMap.EnvironmentDetails.VNetName)"

        $inventory.Add($vnetMap) | Out-Null

        $filteredSubnets = ($vnet.Subnets| Where-Object -FilterScript {$_.Name -match $IaaSPattern})
        if($filteredSubnets.Count -ne 0){
            $nsgResourceIds.Add($filteredSubnets.NetworkSecurityGroup.Id)
        }
    }

    Get-NsgData -NsgResourceId ($nsgResourceIds | Where-Object {$_}) -vnetCount $vnets.Count
    
    $vnet_data = $inventory.GetEnumerator() | `
                    ForEach-Object{ `
                        [PSCustomObject] `
                        @{ ResourceGroupName=$_.EnvironmentDetails.ResourceGroupName; `
                            VNETName=$_.EnvironmentDetails.VNetName; `
                            DNS=$_.VirtualNetwork.DNS; `
                            Subnet=$_.VirtualNetwork.Subnet.Name -join "`r`n"; `
                            RT=([array]$_.VirtualNetwork.Subnet.RT) -join "`r`n"; `
                            Hub=if($_.Peering.Hub){$_.Peering.Hub.Id.Split('/')[-1] -join "`r`n"}else{''}; `
                            Spoke=if($_.Peering.Spokes){$_.Peering.Spokes.Id.Split('/')[-1] -join "`r`n"}else{''}; `
                            AddressSpace=$_.VirtualNetwork.AddressSpace -join "`r`n"; `
                        } `
                    }

    $xls = $vnet_data | Export-Excel -path $xlfile -WorkSheetname Inventory-VNET-$SubscriptionName -TableName $SubscriptionName -AutoSize -PassThru #-AutoSize
    $xls.Workbook.styles.NamedStyles[0].Style.WrapText = $false 
    $xls.Save()
    $xls.Dispose()

    return $vnet_data
}

clean

ForEach ($SubscriptionName in $SubscriptionNames){
    $data = Get-VnetData -SubscriptionName $SubscriptionName
}