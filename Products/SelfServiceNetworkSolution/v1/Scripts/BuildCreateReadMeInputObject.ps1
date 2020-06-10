[CmdletBinding()]
param (
    [Parameter(Mandatory="true", HelpMessage="From AzureFunction body, sent a pipeline variable")]
    [string]
    $RawInputObject,
    [Parameter(Mandatory="true", HelpMessage="Output from AssignIPSpace")]
    [string]
    $VirtualNetworkInfo,
    [Parameter(Mandatory="true", HelpMessage="Output from GetResourceGroupTags")]
    [string]
    $ResourceGroupTags
)

If (![System.String]::IsNullOrWhiteSpace($RawInputObject)) {
    ## Convert InputObject to Json
    $data = $RawInputObject | ConvertFrom-Json
    $vnetInfo = $VirtualNetworkInfo | ConvertFrom-Json
    If (![System.String]::IsNullOrWhiteSpace($VirtualNetworkInfo)) {
        $data | Add-Member -MemberType 'NoteProperty' -Name  'VirtualNetworkInfo' -Value $vnetInfo
    }
    Else {
        Write-Error "VNetName parameter is not set"
    }
    ## Add ResourceGroup tags info
    If (![System.String]::IsNullOrWhiteSpace($ResourceGroupTags)) {
        Write-Verbose -Message ('Adding Resource Group tag information to Environment section of InputObject')
        $EnvironmentRGTags = $ResourceGroupTags | ConvertFrom-Json
    
        $data.Environment | add-member -MemberType NoteProperty -Name 'BusinessApplicationCI' -Value $($EnvironmentRGTags.BusinessApplicationCI)
        $data.Environment | add-member -MemberType NoteProperty -Name 'BillingCode' -Value $($EnvironmentRGTags.BillingCode) 
        $data.Environment | add-member -MemberType NoteProperty -Name 'Provider' -Value $($EnvironmentRGTags.Provider)
        $data.Environment | add-member -MemberType NoteProperty -Name 'AppName' -Value $($EnvironmentRGTags.AppName)
        $data.Environment | add-member -MemberType NoteProperty -Name 'ContactMail' -Value $($EnvironmentRGTags.ContactMail) 
        $data.Environment | add-member -MemberType NoteProperty -Name 'ContactPhone' -Value $($EnvironmentRGTags.ContactPhone)
        $data.Environment | add-member -MemberType NoteProperty -Name 'CIA' -Value $($EnvironmentRGTags.CIA) 
    }
    Else {
        Write-Error "ResourceGroupTags parameter is not set"
    }

}

$rawData = $data | ConvertTo-Json -Compress

Write-Output "##vso[task.setvariable variable=UpdatedRawJson;isOutput=true]$rawData"