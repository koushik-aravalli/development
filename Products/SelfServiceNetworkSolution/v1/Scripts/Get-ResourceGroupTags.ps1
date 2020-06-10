<#
.DESCRIPTION
    This script retrieves Resource Group tags in current Release Pipeline

.PARAMETER RawInputObject <String>
    The InputObject data coming from the Azure Function containing ResourceGroupName and SubscriptionName info

.PARAMETER ResourceGroupName [String]
    The ResourceGroup Name for which the requestor is requesting a Virtual Network Deployment.

.PARAMETER SubscriptionName <String>
    The Subscription Name where the Resource Group is located.

.EXAMPLE
    .\Get-ResourceGroupTags.ps1 -RawInputObject '{"Environment":{"SubscriptionName":"AABNL AZ VDC3S","ResourceGroupName":"esss01-d-rg","ServiceShortName":"demo","ServiceLongName":"demo01","Location":"westeurope","AllowedLocation":"westeurope, northeurope","BusinessApplicationCI":"CI0021829","BillingCode":"NL47356","Provider":"CBSP Azure","AppName":"Demo Self-Service Network IaaS Deployment","ContactMail":"abcd@nl.abnamro","ContactPhone":"003100191920","EnvironmentType":"Development","CIA":"333"},"Subnet":{"size":"11"},"DNS":{"Name":"AzureADDSDNS"},"LoadBalancer":"true","Delegation":{"ResourceGroup":{"Name":"demo01-e-rg-devgroup","ObjectId":"0df12769-5b97-4e74-913b-7a90347fe207"},"SubnetJoin":{"SPNName":"demo01-e-rg-spn","ObjectId":"e3c38fcc-aa83-4b99-b0af-8f99a5418eae"}}}'

.EXAMPLE
    .\Get-ResourceGroupTags.ps1 -SubscriptionName 'AABNL AZ VDC2S' -ResourceGroupName 'demo01-e-rg'
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]

[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $true, ParameterSetName = 'Default')][String] $RawInputObject,
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')][String] $ResourceGroupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')][String] $SubscriptionName
   
)
$ErrorActionPreference = 'Stop'

Write-Host -Message ('RawInputObject: {0}' -f $($RawInputObject))

Try{
    If ($RawInputObject) {
        # Parse RawInputObject
        Write-Host -Message ('RawInputObject parameter is being used')
        $InputObject = ConvertFrom-Json -inputObject $RawInputObject
        $SubscriptionName = $($InputObject.Environment.SubscriptionName)
        $ResourceGroupName =  $($InputObject.Environment.ResourceGroupName)
        Write-Host -Message ('SubscriptionName: {0}, ResourceGroupName: {1}' -f $SubscriptionName, $ResourceGroupName)

        Write-Verbose -Message ('Connecting to Azure Subscription: {0}' -f $SubscriptionName)
        Get-AzSubscription -SubscriptionName $SubscriptionName | Set-AzContext -ErrorAction Stop
    
    }
}
Catch{
    $exp = $PSItem.Exception.Message
    Write-Host "##vso[task.logissue type=error]$exp"
    Write-Error $PSItem.Exception.Message
}

# Try {
#     Write-Verbose -Message ('Connecting to Azure Subscription: {0}' -f $SubscriptionName)
#     Get-AzSubscription -SubscriptionName $SubscriptionName | Set-AzContext -ErrorAction Stop
# }
# Catch
# {
#     Throw ('Failed connect to Azure Subscription {0}' -f $SubscriptionName)
# }

Try {
    Write-Verbose -Message ('Retrieving tags for RG: {0}' -f $ResourceGroupName)
    $ResourceGroup = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    $EnvironmentRGTags = [PSCustomObject]@{        
        'BillingCode' = $ResourceGroup.Tags.'Billing code';
        'Provider' = $ResourceGroup.Tags.'Provider';
        'AppName' = $ResourceGroup.Tags.'AppName';
        'ContactMail' = $ResourceGroup.Tags.'ContactMail';
        'ContactPhone' = $ResourceGroup.Tags.'ContactPhone'; 
        'BusinessApplicationCI' = $ResourceGroup.Tags.'Business Application CI'
        'CIA' =  $ResourceGroup.Tags.'CIA'
    }

    #region Set missing tags for Engineering Subscription
    if ($($InputObject.Environment.EnvironmentType) -eq 'Engineering'){
        $EnvironmentRGTags.BusinessApplicationCI = 'CI0010180'
        $EnvironmentRGTags.CIA = '333'
     }
    #endregion

    #Validate for missing tags.
    Foreach ($Tag in $($EnvironmentRGTags.PSobject.Properties))
    {
        If ($null -eq $Tag.Value) {
            $ErrorMessage = "Empty Tag $($Tag.Name) value found! Cannot continue"
            Write-Host "##vso[task.logissue type=error]$ErrorMessage"
            Write-Error $ErrorMessage
        }
    }

    # Store Environment Resource Group tag properties in release variable
    $Output = $($EnvironmentRGTags | ConvertTo-Json -Compress)
    Write-Host "Output variable EnvironmentRGTags Information:$Output"
    Write-Host "##vso[task.setvariable variable=EnvironmentRGTags;isOutput=true]$Output"

}
Catch {
    Write-Error ('{0} Contact PET1 team to investigate issue.' -f $($_.Exception.Message))
}