<#
Required permissions for the Pernal Access Token:
    Build (read)
    Release (read, write and execute)
#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $false)][String] $OrganizationName = "cbsp-abnamro",
    [Parameter(Mandatory = $false)][String] $ProjectName = 'Azure',
    [Parameter(Mandatory = $true)][String] $ReleaseDefinitionName,
    [Parameter(Mandatory = $true)][String] $StageToStart,
    [Parameter(Mandatory = $true)][String] $PersonalAccessToken
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$headers = @{
  "Authorization" = "Basic $([System.Convert]::ToBase64String([Text.Encoding]::Utf8.GetBytes(":$($PersonalAccessToken)")))"
  "Content-Type"  = "application/json"
}

$uri = "https://vsrm.dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/Release/definitions?searchText=$($ReleaseDefinitionName)&isExactNameMatch=true&api-version=5.1"
$releaseDefinitions = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
If (($releaseDefinitions).GetType().Name -eq 'PSCustomObject' -and $releaseDefinitions.count -eq 1) {
    $uri = "$($releaseDefinitions.value[0].url)?api-version=5.1"
    $releaseDefinition = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
    #region Create new Release from Release Definition
    Write-Verbose "Create new Release based on the Release Definition"
    $artifacts = @()
    ForEach ($defintionArtifact In $releaseDefinition.artifacts) {
        Write-Verbose "  Add Definition Artifact '$($defintionArtifact.alias)'"
        $artifact = [PSCustomObject]@{
            "alias"             = $defintionArtifact.alias
            "instanceReference" = @{
                "id"   = $null
                "name" = $defintionArtifact.definitionReference.definition.name
            }
        }
        # Retrieve build details
        $artifactUrl = "https://dev.azure.com/$($OrganizationName)/$($defintionArtifact.definitionReference.project.name)/_apis/build/definitions/$($defintionArtifact.definitionReference.definition.id)?includeLatestBuilds=true&api-version=5.1"
        $artifactDefinition = Invoke-RestMethod -Uri $artifactUrl -Method Get -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
        If ($defintionArtifact.definitionReference.defaultVersionBranch.id.Length -gt 0) {
            # Retrieve latest build from specific branch
            Write-Verbose "Retrieve latest build from specific branch"
            $artifactUrl = "https://dev.azure.com/$($OrganizationName)/$($defintionArtifact.definitionReference.project.name)/_apis/build/builds?definitions=$($artifactDefinition.id)&statusFilter=completed&resultFilter=succeeded&branchName=refs/heads/$($defintionArtifact.definitionReference.defaultVersionBranch.id)&`$top=1&queryOrder=finishTimeDescending&api-version=5.1"
        }
        Else {
            # Retrieve latest build
            Write-Verbose "Retrieve the latest build"
            $artifactUrl = "https://dev.azure.com/$($OrganizationName)/$($defintionArtifact.definitionReference.project.name)/_apis/build/builds?definitions=$($artifactDefinition.id)&statusFilter=completed&resultFilter=succeeded&`$top=1&queryOrder=finishTimeDescending&api-version=5.1"
        }
        $artifactBuild = Invoke-RestMethod -Uri $artifactUrl -Method Get -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
        $artifact.instanceReference.id = $artifactBuild.value[0].id
        $artifacts += $artifact
    }
    $body = [PSCustomObject]@{
        "artifacts"          = $artifacts
        "definitionId"       = $releaseDefinition.id
        "description"        = "Create Release from SelfService Network Solution Build Pipeline"
        "isDraft"            = $false
        "manualEnvironments" = $null
        "properties"         = $releaseDefinition.properties
        "reason"             = "manual"
    }

    $uri = "https://vsrm.dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/Release/releases?api-version=5.1"
    Write-Verbose "Create Release"
    $release = Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json -Compress -Depth 100) -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
    $releaseId = $release.id
    Write-Verbose "Created Release with Id '$($releaseId)'"
    # A second is enough to settle the Release before retrieving it
    Start-Sleep -Seconds 1
    $uri = "https://vsrm.dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/Release/releases/$($releaseId)?api-version=5.1"
    $release = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -Verbose:$false
    #endregion
    $release.description = "Update Release from Self Service Network Deployment Build Pipeline"
    #$release.variables.subscriptionId.value = $SubscriptionName
    $body = $release | ConvertTo-Json -Depth 100 -Compress

    Write-Verbose "Update Release"
    $result = Invoke-RestMethod -Uri $uri -Method Put -Body $body -Headers $headers -UseBasicParsing -MaximumRedirection 0 -Verbose:$false
    $releaseId = $result.id
    $stage = $result.environments | Where-Object -FilterScript { $_.name -eq $StageToStart }
    $stageId = $stage.id
    Write-Verbose "ReleaseId: $($releaseId)"
    Write-Verbose "ReleaseEnvironmentId: $($stageId)"
    $uri = "https://vsrm.dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/Release/releases/$($releaseId)/environments/$($stageId)?api-version=5.1-preview.6"
    $bodyStart = [PSCustomObject]@{
        "comment" = "Start Release from Self Service Network Deployment Build Pipeline"
        "status"  = "inProgress"
    }
    $body = $bodyStart | ConvertTo-Json -Compress
    Write-Verbose "Start deployment"
    $deploymentStatus = Invoke-RestMethod -Uri $uri -Method Patch -Body $body -Headers $headers -UseBasicParsing -Verbose:$false
    Write-Verbose "Deployment updated to InProgress"
    Do {
        Start-Sleep -Seconds 15
        $deploymentStatus = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -Verbose:$false
        Write-Verbose "$([System.DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss")) - $($deploymentStatus.status)"
    }
    While ($deploymentStatus.status -eq 'notStarted' -or $deploymentStatus.status -eq 'inProgress' -or $deploymentStatus.status -eq 'queued' -or $deploymentStatus.status -eq 'scheduled')

    If ($deploymentStatus.status -eq 'succeeded') {
        # Retrieve the stage triggered after the first stage
        Do {
            Start-Sleep -Seconds 15
            $deploymentStatus = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -Verbose:$false
            Write-Verbose "$([System.DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss")) - $($deploymentStatus.status)"
        }
        While ($deploymentStatus.status -eq 'notStarted' -or $deploymentStatus.status -eq 'inProgress' -or $deploymentStatus.status -eq 'queued' -or $deploymentStatus.status -eq 'scheduled')

        Write-Output "{`"Result`": `"$($deploymentStatus.status)`"}"
        # Get output details
        $regEx = [System.Text.RegularExpressions.Regex]::new("^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z ({.*})$")
        ForEach ($deployStep In $deploymentStatus.deploySteps) {
            ForEach ($releaseDeployPhase In $deployStep.releaseDeployPhases) {
                ForEach ($deploymentJob In $releaseDeployPhase.deploymentJobs) {
                    ForEach ($task In $deploymentJob.tasks | Where-Object -FilterScript { $_.name -eq 'Release Pipeline Deployment Result Output' }) {
                        $logs = Invoke-RestMethod -Uri $task.logUrl -Method Get -Headers $headers -Verbose:$false -UseBasicParsing
                        $lines = $logs.Split("`n")
                        $jsonLines = $lines | ForEach-Object { If ($regEx.IsMatch($_)) { $regEx.Matches($_).Groups[1].Value } }
                        Write-Verbose $jsonLines
                    }
                }
            }
        }

        $uri = "https://vsrm.dev.azure.com/$($OrganizationName)/$($ProjectName)/_apis/Release/releases/$($releaseId)?api-version=5.1"
        $release = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing -Verbose:$false
    }
    Else {
        Write-Output "{`"Result`": `"$($deploymentStatus.status)`"}"
        $issues = @()
        ForEach ($deployStep In $deploymentStatus.deploySteps) {
            ForEach ($releaseDeployPhase In $deployStep.releaseDeployPhases) {
                ForEach ($deploymentJob In $releaseDeployPhase.deploymentJobs) {
                    ForEach ($task In $deploymentJob.tasks | Where-Object -FilterScript { $_.status -eq 'failed' }) {
                        ForEach ($issue In $task.issues) {
                            $issues += ([PSCustomObject]@{
                                "ReleaseId"     = $releaseId
                                "EnvironmentId" = $stageId
                                "Name"          = $deploymentStatus.name.ToString()
                                "Task"          = $task.name.ToString()
                                "Message"       = $issue.message.ToString()
                            })
                        }
                    }
                }
            }
        }
        Write-Output ($issues | ConvertTo-Json)
        Write-Error "The deployment was started, but ended with the result '$($deploymentStatus.status)'"
    }
}
Else {
    Write-Error "No Release Definition found with the name '$($ReleaseDefinitionName)'"
}
