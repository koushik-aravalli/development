[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $FolderPath,
    [Parameter(Mandatory = $false)]
    [String]
    $AzFunctionUrl = "https://networkapi01-e.azurewebsites.net"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Write-Verbose -Message "Start script"

If (-not (Test-Path $FolderPath -PathType Any)) {
    Write-Host "##vso[task.logissue type=error]$FolderPath not valid or inaccessible"
    throw "$FolderPath not valid or inaccessible"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss" 

function Get-SpnAccessToken {
    $creds = @{
        "ClientId"     = $env:servicePrincipalId
        "ClientSecret" = $env:servicePrincipalKey
        "TenantId"     = $env:tenantId
    }

    $tokenEndPoint = "https://login.microsoftonline.com/{0}/oauth2/v2.0/token" -f $creds.TenantId

    $body = @{
        'scope'         = "https://graph.windows.net/.default"
        'client_id'     = $creds.ClientId
        'grant_type'    = 'client_credentials'
        'client_secret' = $creds.ClientSecret
    }

    $params = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers     = @{'accept' = 'application/json' }
        Body        = $body
        Method      = 'POST'
        URI         = $tokenEndPoint
    }

    Write-Verbose "Obtaining access token using deploying service principal credentials for resource."
    $token = Invoke-RestMethod @params
    $accessToken = $token.access_token

    Return $accessToken
}

$azfunc_headers = @{ }

if ($AzFunctionUrl -ne "http://localhost:7071") {
    $azfunc_headers = @{
        Authorization = ('Bearer {0}' -f (Get-SpnAccessToken))
    }
}

Write-Verbose ($azfunc_headers | ConvertTo-Json -depth 3)
# endregion

$artifactFolderName = Get-ChildItem -Path $FolderPath -Filter "AAB*" -Recurse -Directory -Force -ErrorAction SilentlyContinue
Write-Host "ArtifactFoldername: $($artifactFolderName.Name)"

$splitPath = $artifactFolderName.Name.Split('-')
$subscriptionName = $splitPath[0].Replace("AABNL AZ ", "").Replace(" ", "_")
$virtualNetworkName = $splitPath[1].Replace(" ", "_")

Write-Host "SubscriptionName: $subscriptionName"
Write-Host "VirtualNetworkName: $virtualNetworkName"

$AzFunctionUri = "$AzFunctionUrl/api/TriggerArtifactsPublish"
$uniqueBranchName = "Self-Service-$SubscriptionName-$VirtualNetworkName-Readme-$timestamp"

if (Test-Path -Path ('{0}\README.md' -f $artifactFolderName.FullName)) {
    $readmeFile = ('{0}\README.md' -f $artifactFolderName.FullName)
}
else {
    Write-Error -Message "Cannot find README in the $($artifactFolderName.FullName)"
}

$fileContent = [IO.File]::ReadAllText($readmeFile)

$uniquefileName = "README-$timestamp.md"

$Body = @{ 
    branchName      = $uniqueBranchName;
    fileName        = $uniquefileName;
    fileContent     = $fileContent;
    filePath        = "/Solutions/Networking/$SubscriptionName/$VirtualNetworkName/$uniquefileName";
    fileContentType = "rawtext"
} | ConvertTo-Json

Write-Verbose "Azure function $AzFunctionUri is triggered with body $Body"

$Params = @{
    Uri         = $AzFunctionUri
    Headers     = $azfunc_headers
    Body        = $Body
    ContentType = 'application/json'
    Method      = 'Post'
}

Write-Verbose ($Params | ConvertTo-Json)

try {
    $rsp = Invoke-RestMethod @Params -SkipHttpErrorCheck -StatusCodeVariable "rspStatusCode"

    Write-Verbose -Message $rsp

    if ($rspStatusCode -in (200, 409)) {
        Write-Host "##vso[task.setvariable variable=branch_name;isOutput=true]$($uniqueBranchName)"
    }
    else {
        $err = Get-Error
        Write-Verbose -Message $err.Type
    }
}
catch [System.Net.WebException] {
    $err = Get-Error
    Write-Verbose -Message $err.Type
    Write-Verbose -Message "Exception : ($_.Exception)"
}

Write-Verbose -Message "End of Script"