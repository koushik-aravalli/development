<#
.DESCRIPTION
    Retrieves a PBI ID from a specific Azure DevOps Organization, Project, Team from the current sprint which starts with a specific string.

.PARAMETER OrganizationName <String>
    The Azure DevOps Organizational Name.

.PARAMETER ProjectName <String>
    The Azure DevOps Project Name.

.PARAMETER TeamName <String>
    The Team Name within the Azure DevOps Project.

.PARAMETER StartingPBITitle <String>
    The title of the PBI must start with this string.

.PARAMETER OutputVariableName [String]
    Optional output variable name. Default value 'OPSPBIID'.

.PARAMETER PersonalAccessToken [String]
    Personal Access Token with the following permissions (if not specified the System AccessToken is used):
        Organization: the OrganizationName
        Scopes:
            Project and Team
                Read
            Work Items
                Read
#>
[CmdLetBinding()]
Param (
    [Parameter (Mandatory = $true)][ValidateNotNullOrEmpty()][String] $OrganizationName,
    [Parameter (Mandatory = $true)][ValidateNotNullOrEmpty()][String] $ProjectName,
    [Parameter (Mandatory = $true)][ValidateNotNullOrEmpty()][String] $TeamName,
    [Parameter (Mandatory = $true)][ValidateNotNullOrEmpty()][String] $StartingPBITitle,
    [Parameter (Mandatory = $false)][ValidateNotNullOrEmpty()][String] $OutputVariableName = 'OPSPBIID',
    [Parameter (Mandatory = $false)][ValidateNotNullOrEmpty()][String] $PersonalAccessToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseUri = "https://dev.azure.com/$($OrganizationName)"
If ([System.String]::IsNullOrWhiteSpace($PersonalAccessToken)) {
    $accessToken = "Bearer $($env:SYSTEM_ACCESSTOKEN)"
}
Else {
    $accessToken = "Basic $([System.Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$($PersonalAccessToken)")))"
}
$headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}
$opsPBIID = 0

$uri = "$($baseUri)/_apis/projects?api-version=5.1"
$projects = @()
Do {
    $webResult = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    $projects += @(($webResult.Content | ConvertFrom-Json).value)
    If ($webResult.Headers.Keys.Contains('x-ms-continuationtoken')) {
        $uri = "$($baseUri)/_apis/projects?continuationToken=$($webResult.Headers.'x-ms-continuationtoken')&api-version=5.1"
    }
}
While ($webResult.Headers.Keys.Contains('x-ms-continuationtoken'))

If ($project = ($projects | Where-Object -FilterScript { $_.name -eq $ProjectName } )) {
    $ProjectName = $project.name
    Write-Output "Project '$($ProjectName)' exists with id '$($project.id)'"
    $baseUriProject = "$($baseUri)/$($project.id)"

    $uri = "$($baseUri)/_apis/projects/$($project.id)/teams?api-version=5.1-preview.3"
    $teams = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    If ($team = ($teams.value | Where-Object -FilterScript { $_.name -eq $TeamName } )) {
        Write-Output "Team '$($team.name)' found with id '$($team.id)'"
        $baseUriTeam = "$($baseUriProject)/$($team.id)"

        $uri = "$($baseUriTeam)/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=5.1"
        $iterations = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
        If ($iterations.count -eq 1) {
            $iteration = $iterations.value[0]
            Write-Output "Found iteration '$($iteration.name)' within '$($iteration.path)'"

            $uri = "$($baseUriTeam)/_apis/work/teamsettings/iterations/$($iteration.id)/workitems?api-version=5.1-preview.1"
            $items = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            ForEach ($item In $items.workItemRelations) {
                $uri = "$($baseUriProject)/_apis/wit/workitems/$($item.target.id)?api-version=5.1"
                $itemDetails = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                If ($itemDetails.fields.'System.WorkItemType' -eq 'Product Backlog Item') {
                    If ($itemDetails.fields.'System.Title'.Substring(0, $StartingPBITitle.Length) -eq $StartingPBITitle) {
                        Write-Output "Found PBI '$($itemDetails.fields.'System.Title')' with id '$($itemDetails.id)'"
                        $opsPBIID = $itemDetails.id
                        Break
                    }
                }
            }
        }
        Else {
            Write-Error "Current iteration not found within the team $($Team)"
        }
    }
    Else {
        Write-Error "Team '$($TeamName)' not found within Azure DevOps Project $($ProjectName)"
    }
}
Else {
    Write-Error "The Project '$($ProjectName)' doesn't exists or no access to the project"
}

Write-Output "$($OutputVariableName) [$($opsPBIID)]"
Write-Output "##vso[task.setvariable variable=$($OutputVariableName);]$($opsPBIID)"
