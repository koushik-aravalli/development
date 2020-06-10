<#
.DESCRIPTION
    This script creates a new Stage within a current Release Pipeline
    Assumptions:
        Base path in the repository: /CBSP-Azure/CustomerSolutions/Foundation/Networking/
        Parameter SubscriptionName is the next folder within the base path
        Parameter VirtualNetworkName is the next folder(s) within the base path

        Within the folder the files ResourceGroup.parameters.json and vnet.parameters.json exists
    Personal Access Token permissions:
        Agent Pools: Read
        Code: Read
        Graph: Read
        Project and Team: Read
        Release: Read, write, & execute
        Service Connections: Read & query
        Task Groups: Read

.PARAMETER OrganizationName [String]
    The Azure DevOps Organization name, default value cbsp-abnamro.

.PARAMETER ProjectName [String]
    The Azure DevOps Project name within the Organization, default value Azure.

.PARAMETER RepositoryName [String]
    The Azure DevOps Repository within the Project, default value Azure.

.PARAMETER BranchName [String]
    The Repository Branch name, default value master.

.PARAMETER SubscriptionName <String>
    The Subscription Name which is also the folder name within the Repository.

.PARAMETER VirtualNetworkName <String>
    The Virtual Network Name which is also the folder name within the Repository.

.PARAMETER ApprovalGroup [String]
    The Azure DevOps Deployment approval group name, default value [Azure]\Networking Release Approvers.

.PARAMETER NumberOfApprovers [Int]
    The number of approvers, default 1.

.PARAMETER AllowReleaseCreatorApprove [Switch]
    When specified the release creator can also approve the deployment.

.PARAMETER QueueName [String]
    The Azure DevOps Queue name that is used for deployment, default value Azure Pipelines.

.PARAMETER AgentSpecificaton [String]
    The Azure DevOps Queue agent that is used for deployment, default value vs2017-win2016.

.PARAMETER PersonalAccessToken <String>
    Personal Access Token to access Azure DevOps.

.PARAMETER ValidateOnly [Switch]
    Optional parameter to only perform the validation without modifying the Stage.

.EXAMPLE
    .\Create-VirtualNetworkStage.ps1 -SubscriptionName VDC2S -VirtualNetworkName sha02-p-vnet -PersonalAccessToken $PersonalAccessToken
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]

[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $false)][String] $OrganizationName = 'cbsp-abnamro',
    [Parameter(Mandatory = $false)][String] $ProjectName = 'Azure',
    [Parameter(Mandatory = $false)][String] $RepositoryName = 'Azure',
    [Parameter(Mandatory = $false)][String] $BranchName = 'master',
    [Parameter(Mandatory = $true)][ValidatePattern("Engineering|Management|VDC1|(?i)^(VDC)(?:[1-9][0-9]|[2-9]S$)")][String] $SubscriptionName,
    [Parameter(Mandatory = $true)][String] $VirtualNetworkName,
    [Parameter(Mandatory = $false)][String] $ApprovalGroup = '[Azure]\Networking Release Approvers',
    [Parameter(Mandatory = $false)][Int16] $NumberOfApprovers = 1,
    [Parameter(Mandatory = $false)][Switch] $AllowReleaseCreatorApprove,
    [Parameter(Mandatory = $false)][String] $QueueName = 'Azure Pipelines',
    [Parameter(Mandatory = $false)][String] $AgentSpecificaton = 'vs2017-win2016',
    [Parameter(Mandatory = $true)][String] $PersonalAccessToken,
    [Parameter(Mandatory = $false)][Switch] $RemoveSubnetAssignments,
    [Parameter(Mandatory = $false)][Switch] $ValidateOnly,
    [Parameter(Mandatory = $false)][Switch] $BuildAgent,
    [Parameter(Mandatory = $false)][String] $ArtifactsDirectoryPath="/CBSP-Azure/CustomerSolutions/Foundation/Networking/$SubscriptionName/$VirtualNetworkName"
)

$ErrorActionPreference = 'Stop'

$VirtualNetworkName = $VirtualNetworkName.Replace('\', '/')
$headers = @{
    "Authorization" = "Basic $([System.Convert]::ToBase64String([Text.Encoding]::Utf8.GetBytes(":$($PersonalAccessToken)")))"
    "Content-Type"  = "application/json"
}

[System.Void][System.Reflection.Assembly]::LoadWithPartialName('System.Web')

Function Test-FileExists {
    Param (
        [Parameter (Mandatory = $true)][String][AllowEmptyString()] $BaseUriRepository,
        [Parameter (Mandatory = $true)][String] $FilePath,
        [Parameter (Mandatory = $true)][ValidateSet('branch', 'commit', 'tag')][String] $VersionType,
        [Parameter (Mandatory = $true)][String] $Version,
        [Parameter (Mandatory = $true)][HashTable] $Headers
    )

    # Value of BaseUri is empty for Build Artifact
    if([String]::IsNullOrEmpty($BaseUriRepository)){
        Try{
            $filePathInfo = [System.IO.FileInfo]::new($FilePath)
            Write-Host "Searching for $($filePathInfo.FullName)"
            If ([System.IO.File]::Exists($filePathInfo.FullName)) {
                Return $true
            }
            Return $false
        }
        Catch {
            Return $false
        }
    }

    $uri = "$($BaseUriRepository)/items?scopePath=$([System.Web.HttpUtility]::UrlEncode($FilePath))&recursionLevel=none&includeContentMetadata=true&latestProcessedChange=true&download=false&includeLinks=true&`$format=json&versionDescriptor.versionType=$($VersionType)&versionDescriptor.version=$($Version)&api-version=5.1-preview.1"
    Try {
        If ($testResult = Invoke-WebRequest -Uri $uri -Method Get -Headers $Headers -UseBasicParsing) {
            If ($testResult.StatusCode -eq 200) {
                $testResultContent = $testResult.Content | ConvertFrom-Json
                Switch ($testResultContent.count) {
                    0 {
                        Return $false
                    }
                    1 {
                        Return $true
                    }
                    Default {
                        Return $false
                    }
                }
            }
            Else {
                Return $false
            }
        }
    }
    Catch {
        If ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
            Return $false; # Doesn't seem to have the above property
        }
        Else {
            Return $false
        }
    }
}

Function Get-FileContentStream {
    Param (
        [Parameter (Mandatory = $true)][String] $BaseUriRepository,
        [Parameter (Mandatory = $true)][String] $FilePath,
        [Parameter (Mandatory = $true)][ValidateSet('branch', 'commit', 'tag')][String] $VersionType,
        [Parameter (Mandatory = $true)][String] $Version,
        [Parameter (Mandatory = $true)][HashTable] $Headers
    )

    $uri = "$($BaseUriRepository)/items?path=$([System.Web.HttpUtility]::UrlEncode($FilePath))&versionDescriptor.versionType=$($VersionType)&versionDescriptor.version=$($Version)&download=true&api-version=5.1-preview.1"
    $webResult = Invoke-WebRequest -Uri $uri -Method Get -Headers $Headers -ContentType 'application/octet-stream' -UseBasicParsing

    Return $webResult.RawContentStream
}
Function Get-FileContent {
    Param (
        [Parameter (Mandatory = $true)][String][AllowEmptyString()] $BaseUriRepository,
        [Parameter (Mandatory = $true)][String] $FilePath,
        [Parameter (Mandatory = $true)][ValidateSet('branch', 'commit', 'tag')][String] $VersionType,
        [Parameter (Mandatory = $true)][String] $Version,
        [Parameter (Mandatory = $true)][HashTable] $Headers
    )

    if([String]::IsNullOrEmpty($BaseUriRepository)){
        Try{
            $fileContent = Get-Content -Path $FilePath -Encoding UTF8 -Raw
            Return $fileContent
        }
        Catch {
            Return ""
        }
    }

    $fileDataStream = Get-FileContentStream -BaseUriRepository $BaseUriRepository -FilePath $FilePath -VersionType $VersionType -Version $Version -Headers $Headers
    $streamReader = [System.IO.StreamReader]::new($fileDataStream)

    Return $streamReader.ReadToEnd()
}

Function Get-PowerShellTask {
    Param (
        [Parameter (Mandatory = $true)][String] $TaskName,
        [Parameter (Mandatory = $true)][String] $ServiceConnectionId,
        [Parameter (Mandatory = $false)][ValidateSet('FilePath', 'InlineScript')][String] $ScriptType = "FilePath",
        [Parameter (Mandatory = $false)][String] $ScriptFilePath = $null,
        [Parameter (Mandatory = $false)][String] $ScriptArguments = $null,
        [Parameter (Mandatory = $false)][String] $ScriptInline = "",
        [Parameter (Mandatory = $false)][String] $TaskVersion = "3.*",
        [Parameter (Mandatory = $false)][String] $PowerShellVersion = "6.7.0"
    )

    $returnObject = [PSCustomObject]@{
        "alwaysRun"        = $false
        "condition"        = "succeeded()"
        "continueOnError"  = $false
        "definitionType"   = "task"
        "enabled"          = $true
        "inputs"           = [PSCustomObject]@{
            "ConnectedServiceNameSelector" = "ConnectedServiceNameARM"
            "ConnectedServiceName"         = ""
            "ConnectedServiceNameARM"      = $ServiceConnectionId
            "ScriptType"                   = $ScriptType
            "ScriptPath"                   = $ScriptFilePath
            "Inline"                       = $ScriptInline
            "ScriptArguments"              = $ScriptArguments
            "errorActionPreference"        = "stop"
            "FailOnStandardError"          = "false"
            "TargetAzurePs"                = "OtherVersion"
            "CustomTargetAzurePs"          = $PowerShellVersion
        }
        "name"             = $TaskName
        "overrideInputs"   = @{ }
        "refName"          = ""
        "taskId"           = "72a1931b-effb-4d2e-8fd8-f8472a07cb62"
        "timeoutInMinutes" = 0
        "version"          = $TaskVersion
    }
    If ($TaskVersion -eq "4.*") {
        $returnObject | Add-Member -MemberType NoteProperty -Name 'pwsh' -Value 'true'
        $returnObject | Add-Member -MemberType NoteProperty -Name 'workingDirectory' -Value ''
    }

    Return $returnObject
}

Function Get-DelegationTaskResourceGroup {
    Param (
        [Parameter (Mandatory = $true)][String] $TaskName,
        [Parameter (Mandatory = $true)][String] $ServiceConnectionId,
        [Parameter (Mandatory = $true)][String] $AzureObjectIdVariable,
        [Parameter (Mandatory = $true)][String] $RoleToAssign
    )

    Return Get-PowerShellTask -TaskName $TaskName -ServiceConnectionId $ServiceConnectionId -ScriptFilePath "`$(System.DefaultWorkingDirectory)/Resource Group v2.0/Scripts/Assign-ResourceGroupPermission.ps1" -ScriptArguments "-resourceGroupName '`$(ResourceGroupName)' -AzureAdObjectId '`$($($AzureObjectIdVariable))' -RoleToAssign '$($RoleToAssign)'"
}

Function Get-DelegationTaskSubnet {
    Param (
        [Parameter (Mandatory = $true)][String] $TaskName,
        [Parameter (Mandatory = $true)][String] $ServiceConnectionId,
        [Parameter (Mandatory = $true)][String] $VirtualNetworkName,
        [Parameter (Mandatory = $true)][String] $SubnetName,
        [Parameter (Mandatory = $true)][String] $AzureObjectIdVariable,
        [Parameter (Mandatory = $true)][String] $RoleToAssign
    )

    Return Get-PowerShellTask -TaskName $TaskName -ServiceConnectionId $ServiceConnectionId -ScriptFilePath "`$(System.DefaultWorkingDirectory)/VirtualNetwork v1.0/Scripts/Assign-SubnetRbac.ps1" -ScriptArguments "-ResourceGroupName '`$(ResourceGroupName)' -VirtualNetworkName '$($VirtualNetworkName)' -SubnetName '$($SubnetName)' -AzureAdObjectId '`$($($AzureObjectIdVariable))' -RoleToAssign '$($RoleToAssign)'"
}

$baseUri = "https://dev.azure.com/$($OrganizationName)"
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

If ($project = ($projects | Where-Object -FilterScript { $_.name -eq $ProjectName })) {
    $baseUriProject = "$($baseUri)/$($project.id)"
    $baseUriRepository = "$($baseUriProject)/_apis/git/repositories/$($RepositoryName)"
    $baseUriVsrmProject = "https://vsrm.dev.azure.com/$($OrganizationName)/$($project.id)"
    $baseUriVssps = "https://vssps.dev.azure.com/$($OrganizationName)"

    # Retrieve pre-approval group
    If (![System.String]::IsNullOrWhiteSpace($ApprovalGroup)) {
        $scopeResult = Invoke-RestMethod -Uri "$($baseUriVssps)/_apis/graph/descriptors/$($project.id)?api-version=5.1-preview.1" -Method Get -Headers $headers -UseBasicParsing
        $groups = @()
        $uri = "$($baseUriVssps)/_apis/graph/groups?subjectTypes=vssgp&scopeDescriptor=$($scopeResult.value)&api-version=5.1-preview.1"
        Do {
            $results = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            $groups += @(($results.Content | ConvertFrom-Json).value)
            If ($results.Headers.ContainsKey('X-MS-ContinuationToken')) {
                $uri = "$($baseUriVssps)/_apis/graph/groups?subjectTypes=vssgp&scopeDescriptor=$($scopeResult.value)&continuationToken=$($results.Headers.Item('X-MS-ContinuationToken'))&api-version=5.1-preview.1"
            }
        }
        While ($results.Headers.ContainsKey('X-MS-ContinuationToken'))
        $group = $groups | Where-Object -FilterScript { $_.principalName -eq $ApprovalGroup }
        If ($null -eq $group) {
            Write-Error "The group '$($ApprovalGroup)' was not found"
        }
    }
    Else {
        $group = $null
    }

    # Retrieve the Readme file
    $readmeFile = ""
    $filePath = "$ArtifactsDirectoryPath\README.md"
    if ($BuildAgent){
        $baseUriRepository = $null
    }
    If ($BranchName -ne 'master') {
        If (Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version $BranchName -Headers $headers) {
            Write-Host "Retrieve file '$($filePath)' from the branch '$($BranchName)'"
            $readmeFile = Get-FileContent -BaseUriRepository $BaseUriRepository -FilePath $filePath -VersionType branch -Version $BranchName -Headers $headers
        }
        Else {
            Write-Warning "File '$($filePath)' not found within the branch '$($BranchName)'"
        }
    }
    If ([System.String]::IsNullOrWhiteSpace($readmeFile)) {
        If (Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version 'master' -Headers $headers) {
            Write-Host "Retrieve file '$($filePath)' from the branch 'master'"
            $readmeFile = Get-FileContent -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version 'master' -Headers $headers
        }
        Else {
            Write-Error "File '$($filePath)' not found"
        }
    }

    # Retrieve the Resource Group Name
    If (Test-FileExists -BaseUriRepository $baseUriRepository -FilePath "$ArtifactsDirectoryPath\ResourceGroup.parameters.json" -VersionType branch -Version $BranchName -Headers $headers) {
        $resourceGroupFile = Get-FileContent -BaseUriRepository $BaseUriRepository -FilePath "$ArtifactsDirectoryPath\ResourceGroup.parameters.json" -VersionType branch -Version $BranchName -Headers $headers
        $resourceGroupJson = $resourceGroupFile | ConvertFrom-Json
        If ([System.String]::IsNullOrWhiteSpace($resourceGroupJson.Environment)) {
            $resourceGroupName = "$($resourceGroupJson.ServiceName)-rg"
        }
        Else {
            $resourceGroupName = "$($resourceGroupJson.ServiceName)-$($resourceGroupJson.Environment)-rg"
        }
        $resourceGroupName = $resourceGroupName.ToLower()
        Write-Host "Resource Group Name: $($resourceGroupName)"
    }
    Else {
        Write-Error "The file '$ArtifactsDirectoryPath\ResourceGroup.parameters.json' doesn't exists in the $($BranchName) branch"
    }

    Write-Host "Retrieve Azure DevOps Task Groups"
    $uri = "$($baseUriProject)/_apis/distributedtask/taskgroups?api-version=5.1-preview.1"
    $taskGroups = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    $taskResourceGroup = $taskGroups.value | Where-Object -FilterScript { $_.name -eq 'CBSP-Deploy Resource Group v2.0' }

    $virtualNetworkFile = ""
    $filePath = "$ArtifactsDirectoryPath\vnet.parameters.json"
    If ($BranchName -ne 'master') {
        If (Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version $BranchName -Headers $headers) {
            Write-Host "Retrieve file '$($filePath)' from the branch '$($BranchName)'"
            $virtualNetworkFile = Get-FileContent -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version $BranchName -Headers $headers
        }
        Else {
            Write-Warning "File '$($filePath)' not found within the branch '$($BranchName)'"
        }
    }
    If ([System.String]::IsNullOrWhiteSpace($virtualNetworkFile)) {
        If (Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version 'master' -Headers $headers) {
            Write-Host "Retrieve file '$($filePath)' from the branch 'master'"
            $virtualNetworkFile = Get-FileContent -BaseUriRepository $baseUriRepository -FilePath $filePath -VersionType branch -Version 'master' -Headers $headers
        }
        Else {
            Write-Error "File '$($filePath)' not found"
        }
    }
    If (![System.String]::IsNullOrWhiteSpace($virtualNetworkFile)) {
        Write-Host "File '$($filePath)' retrieved"
        If ($virtualNetworkJson = $VirtualNetworkFile | ConvertFrom-Json) {
            $virtualNetworkJson.parameters.vnetName.value = $virtualNetworkJson.parameters.vnetName.value.ToLower()
            # Retrieve the Task Group for with or without peering
            $filePathPeering = "$ArtifactsDirectoryPath\VnetPeering.parameters.json"
            $filePathPeerVnet = "$ArtifactsDirectoryPath\PeerVnetPeering.parameters.json"
            If ((Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $filePathPeering -VersionType branch -Version $BranchName -Headers $headers) -and (Test-FileExists -BaseUriRepository $BaseUriRepository -FilePath $filePathPeerVnet -VersionType branch -Version $BranchName -Headers $headers)) {
                Write-Host "Found the files 'VnetPeering.parameters.json' and 'PeerVnetPeering.parameters.json'"
                Write-Host "Virtual Network $($virtualNetworkJson.parameters.vnetName.value) with peering" -ForegroundColor Green
                $taskGroup = $taskGroups.value | Where-Object -FilterScript { $_.name -eq 'CBSP-Deploy Foundation Virtual Network v1.0' }
            }
            Else {
                Write-Host "Files 'VnetPeering.parameters.json' and 'PeerVnetPeering.parameters.json' not found"
                Write-Host "Virtual Network $($virtualNetworkJson.parameters.vnetName.value) without peering" -ForegroundColor Yellow
                $taskGroup = $taskGroups.value | Where-Object -FilterScript { $_.name -eq 'CBSP-Deploy Foundation Virtual Network v1.0 w/o peering' }
            }
            # Network Security Groups
            ForEach ($subnetName In $virtualNetworkJson.parameters.subnetName.value) {
                $nsgFileName = "$($virtualNetworkJson.parameters.vnetName.value)-$($subnetName.ToLower())-nsg.parameters.json"
                $nsgFilePath = "$ArtifactsDirectoryPath\$($nsgFileName)"
                If (!(Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $nsgFilePath -VersionType branch -Version $BranchName -Headers $headers)) {
                    If ($BranchName -ne 'master') {
                        If (!(Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $nsgFilePath -VersionType branch -Version 'master' -Headers $headers)) {
                            Write-Host "File '$($nsgFileName)' not found within branch '$($BranchName)' and 'master'" -ForegroundColor Red
                        }
                    }
                    Else {
                        Write-Host "File '$($nsgFileName)' not found within branch '$($BranchName)'" -ForegroundColor Red
                    }
                }
                Else {
                    Write-Host "NSG file '$($nsgFileName)' found"
                }
            }
            # Route Table
            ForEach ($subnetName In $virtualNetworkJson.parameters.subnetName.value) {
                $routetableFileName = "$($virtualNetworkJson.parameters.vnetName.value)-$($subnetName.ToLower())-routetable.parameters.json"
                $routetableFilePath = "$ArtifactsDirectoryPath\$($routetableFileName)"
                If (!(Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $routetableFilePath -VersionType branch -Version $BranchName -Headers $headers)) {
                    If ($BranchName -ne 'master') {
                        If (!(Test-FileExists -BaseUriRepository $baseUriRepository -FilePath $routetableFilePath -VersionType branch -Version 'master' -Headers $headers)) {
                            Write-Host "File '$($routetableFileName)' not found within branch '$($BranchName)' and 'master'" -ForegroundColor Yellow
                        }
                    }
                    Else {
                        Write-Host "File '$($routetableFileName)' not found within branch '$($BranchName)'" -ForegroundColor Yellow
                    }
                }
                Else {
                    Write-Host "Route Table file '$($routetableFileName)' found"
                }
            }

            $uri = "$($baseUriVsrmProject)/_apis/Release/definitions?api-version=5.1-preview.3&searchText=Foundation-Networking-$($SubscriptionName)"
            $releasePipelines = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            If ($releasePipelines.count -eq 1) {
                $releasePipeline = Invoke-RestMethod -Uri "$($releasePipelines.value[0].url)?api-version=5.1-preview.3" -Method Get -Headers $headers -UseBasicParsing
                # Service Connection
                $uri = "$($baseUriProject)/_apis/serviceendpoint/endpoints?api-version=5.1-preview.1"
                $serviceConnections = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                $serviceConnectionName = "devops-azure-$($SubscriptionName.ToLower())"
                If ($serviceConnection = ($serviceConnections.value | Where-Object -FilterScript { $_.name -eq $serviceConnectionName })) {
                    Write-Host "Found Service Connection '$($serviceConnection.name)'"
                }
                Else {
                    Write-Error "No Service Connection found with the name '$($serviceConnectionName)'"
                }
                $serviceConnectionName = "devops-azure-management"
                If ($serviceConnectionManagement = ($serviceConnections.value | Where-Object -FilterScript { $_.name -eq $serviceConnectionName })) {
                    Write-Host "Found Service Connection '$($serviceConnectionManagement.name)'"
                }
                Else {
                    Write-Error "No Service Connection found with the name '$($serviceConnectionName)'"
                }

                # Queue
                $uri = "$($baseUriProject)/_apis/distributedtask/queues?api-version=5.1-preview.1"
                $queues = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                If ($queue = ($queues.value | Where-Object -FilterScript { $_.pool.poolType -eq 'automation' -and $_.pool.isHosted -eq $true -and $_.name -eq $QueueName })) {
                    $queueId = $queue.id
                    $uri = "$($baseUriProject)/_apis/distributedtask/queues/$($queueId)?api-version=5.1-preview.1"
                }
                Else {
                    Write-Error "No queue found with the name '$($QueueName)'"
                }

                $regEx = [System.Text.RegularExpressions.Regex]::new(": ($($virtualNetworkJson.parameters.vnetName.value))", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $stages = @($releasePipeline.environments | Where-Object -FilterScript { $regEx.IsMatch($_.name) })
                If ($stages.Count -eq 1) {
                    $stageRank = $releasePipeline.environments.id.indexOf($stages[0].id)
                    $stage = $releasePipeline.environments[$stageRank]
                    Write-Host "Found existing Stage for Virtual Network '$($virtualNetworkJson.parameters.vnetName.value)' with as Stage name '$($stage.name)' ranked at $($stageRank + 1)"
                    $stage.deployPhases[0].workflowTasks = @()
                    $stage.deployPhases[0].deploymentInput.queueId = $queueId
                    $stage.deployPhases[0].deploymentInput.agentSpecification = [PSCustomObject]@{
                        "identifier" = $AgentSpecificaton
                    }
                    $releasePipeline | Add-Member -MemberType NoteProperty -Name "comment" -Value "Update Stage '$($stage.name)'"
                }
                ElseIf ($stages.Count -eq 0) {
                    Write-Host "Create new Stage definition for Virtual Network '$($virtualNetworkJson.parameters.vnetName.value)'"
                    Switch ($SubscriptionName) {
                        "Engineering" {
                            $stagePrefix = "ENG"
                        }
                        "Management" {
                            $stagePrefix = "MGT"
                        }
                        Default {
                            $stagePrefix = $SubscriptionName.ToUpper()
                        }
                    }
                    $stage = [PSCustomObject]@{
                        "name"                = "$($stagePrefix): $($virtualNetworkJson.parameters.vnetName.value)"
                        "rank"                = $releasePipeline.environments.Count
                        "variables"           = $null
                        "retentionPolicy"     = [PSCustomObject]@{
                            "daysToKeep"     = 30
                            "releasesToKeep" = 3
                            "retainBuild"    = $true
                        }
                        "preDeployApprovals"  = [PSCustomObject]@{
                            "approvals"       = @(
                                [PSCustomObject]@{
                                    "rank"             = 1
                                    "isAutomated"      = $true
                                    "isNotificationOn" = $false
                                }
                            )
                            "approvalOptions" = [PSCustomObject]@{
                                "requiredApproverCount"                                   = $null
                                "releaseCreatorCanBeApprover"                             = $false
                                "autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped" = $false
                                "enforceIdentityRevalidation"                             = $false
                                "timeoutInMinutes"                                        = 0
                                "executionOrder"                                          = "beforeGates"
                            }
                        }
                        "postDeployApprovals" = [PSCustomObject]@{
                            "approvals"       = @(
                                [PSCustomObject]@{
                                    "rank"             = 1
                                    "isAutomated"      = $true
                                    "isNotificationOn" = $false
                                }
                            )
                            "approvalOptions" = [PSCustomObject]@{
                                "requiredApproverCount"                                   = $null
                                "releaseCreatorCanBeApprover"                             = $false
                                "autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped" = $false
                                "enforceIdentityRevalidation"                             = $false
                                "timeoutInMinutes"                                        = 0
                                "executionOrder"                                          = "afterSuccessfulGates"
                            }
                        }
                        "deployPhases"        = @(
                            [PSCustomObject]@{
                                "name"            = "Agent phase"
                                "rank"            = 1
                                "phaseType"       = "agentBasedDeployment"
                                "deploymentInput" = [PSCustomObject]@{
                                    "parallelExecution"         = [PSCustomObject]@{
                                        "parallelExecutionType" = "none"
                                    }
                                    "skipArtifactsDownload"     = $false
                                    "artifactsDownloadInput"    = [PSCustomObject]@{
                                        "downloadInputs" = ""
                                    }
                                    "queueId"                   = $queueId
                                    "agentSpecification"        = [PSCustomObject]@{
                                        "identifier" = $AgentSpecificaton
                                    }
                                    "demands"                   = @()
                                    "enableAccessToken"         = $false
                                    "timeoutInMinutes"          = 0
                                    "jobCancelTimeoutInMinutes" = 1
                                    "condition"                 = "succeeded()"
                                    "overrideInputs"            = @{ }
                                }
                                "workflowTasks"   = @()
                            }
                        )
                    }
                    $comment = "Add Stage '$($stage.name)' to the current Stage(s)"
                    Write-Host $comment
                    $releasePipeline | Add-Member -MemberType NoteProperty -Name "comment" -Value $comment
                    $stageRank = $releasePipeline.environments.Count
                    $releasePipeline.environments += $stage
                }
                Else {
                    Write-Error "Found $($stages.Count) stages. Stage names: $([System.String]::Join(", ", $releasePipeline.environments.name))"
                }
                # Add approval
                If ($null -ne $group) {
                    $approval = $stage.preDeployApprovals.approvals[0]
                    $approval.isAutomated = $false
                    $approver = [PSCustomObject]@{
                        "displayName" = $group.principalName
                        "id"          = $group.originId
                        "uniqueName"  = "$($group.domain)\\$($group.displayName)"
                        "isContainer" = $true
                        "descriptor"  = $group.descriptor
                    }
                    If ($null -eq ($approval | Get-Member -MemberType NoteProperty -Name approver)) {
                        $approval | Add-Member -MemberType NoteProperty -Name 'approver' -Value $approver
                    }
                    Else {
                        $approval.approver = $approver
                    }
                    $stage.preDeployApprovals.approvals[0] = $approval
                    $stage.preDeployApprovals.approvalOptions.requiredApproverCount = $NumberOfApprovers
                    $stage.preDeployApprovals.approvalOptions.releaseCreatorCanBeApprover = $AllowReleaseCreatorApprove.IsPresent
                    $stage.preDeployApprovals.approvalOptions.timeoutInMinutes = 43200
                }
                Else {
                    Write-Warning "Stage has no approval"
                }

                # Resource Group v2.0 Task Group
                $workflowTask = [PSCustomObject]@{
                    "alwaysRun"        = $true
                    "condition"        = "succeededOrFailed()"
                    "continueOnError"  = $false
                    "definitionType"   = "metaTask"
                    "enabled"          = $true
                    "inputs"           = @{ }
                    "name"             = "Deploy Resource Group v2.0: $($resourceGroupName)"
                    "overrideInputs"   = @{ }
                    "refName"          = ""
                    "taskId"           = $taskResourceGroup.id
                    "timeoutInMinutes" = 0
                    "version"          = "$($taskResourceGroup.version.major).*"
                }
                ForEach ($taskGroupInput In $taskResourceGroup.inputs) {
                    $taskGroupInputName = $taskGroupInput.name
                    $workflowTask.inputs.$taskGroupInputName = $taskGroupInput.defaultValue
                }
                $workflowTask.inputs.Subscription = $ServiceConnection.id
                $workflowTask.inputs.ResourceGroupParameterFile = "`$(System.DefaultWorkingDirectory)/Foundation/Parameters/Networking/$($SubscriptionName)/$($VirtualNetworkName)/ResourceGroup.parameters.json"
                $stage.deployPhases[0].workflowTasks += $workflowTask

                If ($RemoveSubnetAssignments.IsPresent) {
                    $taskName = "Remove old RBAC assignments on Virtual Network Subnets"
                    $scriptFilePath = "`$(System.DefaultWorkingDirectory)/Subscription/Scripts/Assign-PolicyDefinition.ps1"
                    $scriptArguments = "-PolicyDefinitionDisplayName 'CBSP Azure Virtual Network v1 - Enforce Subnet-NSG-RT relationship' -PolicyAssignmentName 'Enforce Subnet-NSG-RT relationship' -ResourceGroupName '`$(ResourceGroupName)'"
                    Write-Host "Add task: $($taskName)"
                    $inlineScript = @'
$ResourceGroupName = '$(ResourceGroupName)'
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName
$roleAssignments = Get-AzRoleAssignment -Scope $resourceGroup.ResourceId | Where-Object -FilterScript { $_.Scope.StartsWith($resourceGroup.ResourceId) -and $_.Scope.Contains("Microsoft.Network/virtualNetworks") -and ($_.RoleDefinitionName -eq 'Virtual Machine Contributor' -or $_.RoleDefinitionName -eq 'Storage Account Contributor') }
$roleAssignments | ForEach-Object {
    $roleAssignment = $_
    Get-AzResourceLock -Scope $roleAssignment.Scope | Where-Object -FilterScript { $_.Properties.level -eq 'CanNotDelete' } | ForEach-Object {
        Write-Host "Remove lock $($_.Name)"
        $_ | Remove-AzResourceLock -Force -Confirm:$false
    }
}
Start-Sleep -Seconds 10
$roleAssignments | ForEach-Object {
    Write-Host $_.RoleAssignmentId
    $_ | Remove-AzRoleAssignment -Confirm:$false
}
'@
                    $workflowTask = Get-PowerShellTask -TaskName $taskName -ServiceConnectionId $serviceConnection.id -ScriptType 'InlineScript' -ScriptInline $inlineScript -TaskVersion "4.*" -PowerShellVersion "2.6.0"
                    $stage.deployPhases[0].workflowTasks += $workflowTask
                }

                # Virtual Network v1.0 Task Group
                $workflowTask = [PSCustomObject]@{
                    "alwaysRun"        = $true
                    "condition"        = "succeededOrFailed()"
                    "continueOnError"  = $false
                    "definitionType"   = "metaTask"
                    "enabled"          = $true
                    "inputs"           = @{ }
                    "name"             = "$($taskGroup.name): $($virtualNetworkJson.parameters.vnetName.value)"
                    "overrideInputs"   = @{ }
                    "refName"          = ""
                    "taskId"           = $taskGroup.id
                    "timeoutInMinutes" = 0
                    "version"          = "$($taskGroup.version.major).*"
                }
                ForEach ($taskGroupInput In $taskGroup.inputs) {
                    $taskGroupInputName = $taskGroupInput.name
                    $workflowTask.inputs.$taskGroupInputName = $taskGroupInput.defaultValue
                }
                $workflowTask.inputs.DestinationServiceEndpoint = $ServiceConnection.id
                $workflowTask.inputs.ManagementServiceEndpoint = $ServiceConnectionManagement.id
                $workflowTask.inputs.SubscriptionFolderName = $SubscriptionName
                $workflowTask.inputs.VnetFolderName = $VirtualNetworkName
                $stage.deployPhases[0].workflowTasks += $workflowTask

                # Delegation
                If (![String]::IsNullOrWhiteSpace($readmeFile)) {
                    $checkBoxes = [System.Text.RegularExpressions.Regex]::new("- \[X\] (.*)[\r|]?\n", [System.Text.RegularExpressions.RegexOptions]::Multiline).Matches($readmeFile)
                    For ($i = 0; $i -lt $checkBoxes.Count; $i++) {
                        $checkBox = $checkBoxes[$i]
                        If ($checkBox.Groups[1].Value -eq "Enforce Subnet-NSG-RT relationship") {
                            $taskName = "Assign Enforce Subnet-NSG-RT relationship Policy"
                            $scriptFilePath = "`$(System.DefaultWorkingDirectory)/Subscription/Scripts/Assign-PolicyDefinition.ps1"
                            $scriptArguments = "-PolicyDefinitionDisplayName 'CBSP Azure Virtual Network v1 - Enforce Subnet-NSG-RT relationship' -PolicyAssignmentName 'Enforce Subnet-NSG-RT relationship' -ResourceGroupName '`$(ResourceGroupName)'"
                            Write-Host "Add task: $($taskName)"
                            $workflowTask = Get-PowerShellTask -TaskName $taskName -ServiceConnectionId $serviceConnection.id -ScriptFilePath $scriptFilePath -ScriptArguments $scriptArguments
                            $stage.deployPhases[0].workflowTasks += $workflowTask
                        }
                        ElseIf ($checkBox.Groups[1].Value.StartsWith("Resource Group: ")) {
                            $regex2 = [System.Text.RegularExpressions.Regex]::new("Resource Group: (.*) ``(.*)``: ``(.*)``")
                            If ($regex2.IsMatch($checkBox.Groups[1].Value)) {
                                $azureADDisplayName = $regex2.Matches($checkBox.Groups[1].Value).Groups[1].Value
                                $azureADObjectID = $regex2.Matches($checkBox.Groups[1].Value).Groups[2].Value
                                $roleToAssign = $regex2.Matches($checkBox.Groups[1].Value).Groups[3].Value
                                $taskName = "Assign Group $($azureADDisplayName) as $($roleToAssign) on the Resource Group"
                                If ($null -eq $stage.variables) {
                                    $stage.variables = ([PSCustomObject]@{
                                        "$($azureADDisplayName)" = [PSCustomObject]@{
                                            "value" = "$($azureADObjectID)"
                                        }
                                    })
                                }
                                Else {
                                    If ($null -eq ($stage.variables | Get-Member -MemberType NoteProperty -Name $azureADDisplayName)) {
                                        $stage.variables | Add-Member -MemberType NoteProperty -Name "$($azureADDisplayName)" -Value ([PSCustomObject]@{ "value" = "$($azureADObjectID)" })
                                    }
                                }
                                Write-Host "Add task: $($taskName)"
                                $workflowTask = Get-DelegationTaskResourceGroup -TaskName $taskName -ServiceConnectionId $serviceConnection.id -AzureObjectIdVariable $azureADDisplayName -RoleToAssign $roleToAssign
                                $stage.deployPhases[0].workflowTasks += $workflowTask
                            }
                            Else {
                                Write-Error "Error parsing Resource Group: $($checkBox.Groups[1].Value), regex: Resource Group: (.*) ``(.*)``: ``(.*)``"
                            }
                        }
                        ElseIf ($checkBox.Groups[1].Value.StartsWith("Subnet Join for ")) {
                            $regex2 = [System.Text.RegularExpressions.Regex]::new("Subnet Join for (.*): (.*) ``(.*)``: ``(.*)``")
                            If ($regex2.IsMatch($checkBox.Groups[1].Value)) {
                                $subnetName = $regex2.Matches($checkBox.Groups[1].Value).Groups[1].Value
                                $roleToAssign = $regex2.Matches($checkBox.Groups[1].Value).Groups[4].Value
                                $azureADDisplayName = $regex2.Matches($checkBox.Groups[1].Value).Groups[2].Value
                                $azureADObjectID = $regex2.Matches($checkBox.Groups[1].Value).Groups[3].Value
                                $taskName = "Delegate SelfService Subnet-Join on $($VirtualNetworkName.ToLower())/$($subnetName) to '$($azureADDisplayName)' using '$($roleToAssign)' role"
                                If ($null -eq $stage.variables) {
                                    $stage.variables = ([PSCustomObject]@{
                                        "$($azureADDisplayName)" = [PSCustomObject]@{
                                            "value" = "$($azureADObjectID)"
                                        }
                                    })
                                }
                                Else {
                                    If ($null -eq ($stage.variables | Get-Member -MemberType NoteProperty -Name $azureADDisplayName)) {
                                        $stage.variables | Add-Member -MemberType NoteProperty -Name "$($azureADDisplayName)" -Value ([PSCustomObject]@{ "value" = "$($azureADObjectID)" })
                                    }
                                }
                                If ($null -eq ($stage.deployPhases[0].workflowTasks | Where-Object -FilterScript { $_.name -eq $taskName })) {
                                    Write-Host "Add task: $($taskName)"
                                    $workflowTask = Get-DelegationTaskSubnet -TaskName $taskName -ServiceConnectionId $ServiceConnection.id -VirtualNetworkName $VirtualNetworkName.ToLower() -SubnetName $subnetName -AzureObjectIdVariable $azureADDisplayName -RoleToAssign $roleToAssign
                                    $stage.deployPhases[0].workflowTasks += $workflowTask
                                }
                                # Add additional delegation for Storage Account Service Endpoint
                                If ($roleToAssign -eq 'Virtual Machine Contributor') {
                                    $subnetIndex = $virtualNetworkJson.parameters.subnetName.value.indexOf($subnetName)
                                    If ($null -ne ($virtualNetworkJson.parameters.subnetServiceEndpoints.value[$subnetIndex] | Where-Object -FilterScript { $_.service -eq 'Microsoft.Storage' })) {
                                        $roleToAssign = 'Storage Account Contributor'
                                        $taskName = "Delegate SelfService Subnet-Join on $($VirtualNetworkName.ToLower())/$($subnetName) to '$($azureADDisplayName)' using '$($roleToAssign)' role"
                                        If ($null -eq ($stage.deployPhases[0].workflowTasks | Where-Object -FilterScript { $_.name -eq $taskName })) {
                                            Write-Host "Add task: $($taskName)"
                                            $workflowTask = Get-DelegationTaskSubnet -TaskName $taskName -ServiceConnectionId $ServiceConnection.id -VirtualNetworkName $VirtualNetworkName.ToLower() -SubnetName $subnetName -AzureObjectIdVariable $azureADDisplayName -RoleToAssign $roleToAssign
                                            $stage.deployPhases[0].workflowTasks += $workflowTask
                                        }
                                    }
                                }
                            }
                            Else {
                                Write-Error "Error parsing Subnet Join for: $($checkBox.Groups[1].Value), regex: Subnet Join for (.*): (.*) ``(.*)``: ``(.*)``"
                            }
                        }
                        ElseIf ($checkBox.Groups[1].Value -eq "Spoke/Spoke") {
                            $regex2 = [System.Text.RegularExpressions.Regex]::new("Peering to ``(.*)``.*``(.*)``.*``(.*)``")
                            $taskGroupPeering = $taskGroups.value | Where-Object -FilterScript { $_.name -eq 'CBSP-Deploy Foundation Virtual Network Peering v1.0' }
                            While ($i -lt $checkBoxes.Count) {
                                $i++
                                $checkBox = $checkBoxes[$i]
                                If ($regex2.IsMatch($checkBox.Groups[1].Value)) {
                                    $spokePeeringParameters = $regex2.Matches($checkBox.Value)

                                    $filePathSpokePeering = "$ArtifactsDirectoryPath\VnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"
                                    $filePathPeerSpokePeering = "$ArtifactsDirectoryPath\PeerVnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"

                                    If ((Test-FileExists -BaseUriRepository $BaseUriRepository -FilePath $filePathSpokePeering -VersionType branch -Version $BranchName -Headers $headers) -and (Test-FileExists -BaseUriRepository $BaseUriRepository -FilePath $filePathPeerSpokePeering -VersionType branch -Version $BranchName -Headers $headers)) {
                                        If ($spokeServiceConnection = ($serviceConnections.value | Where-Object -FilterScript { $_.name.ToLower().StartsWith("devops-azure-") `
                                                                                                                                -and $_.data.environment -eq 'AzureCloud' `
                                                                                                                                -and $_.data.scopeLevel -eq 'Subscription' `
                                                                                                                                -and $_.data.subscriptionId -eq $spokePeeringParameters.Groups[3].Value `
                                                                                                                                -and $_.data.subscriptionName -eq "AABNL AZ $($_.name.Split('-', 3)[2])" })) {
                                            If (@($spokeServiceConnection).Count -eq 0) {
                                                Write-Error "No Service Connection found for Subscription Id '$($spokePeeringParameters.Groups[3].Value)' and Subscription Name 'AABNL AZ $(($_.name.Split('-', 3)[2]).ToUpper())'"
                                            }
                                            ElseIf (@($spokeServiceConnection).Count -gt 1) {
                                                Write-Error "Found multiple Service Connections found for Subscription Id '$($spokePeeringParameters.Groups[3].Value)' and Subscription Name 'AABNL AZ $(($_.name.Split('-', 3)[2]).ToUpper())'"
                                            }

                                            Write-Host "Create spoke/spoke peering to subscription '$($spokeServiceConnection.data.subscriptionName)', Resource Group '$($spokePeeringParameters.Groups[2].Value)' and Virtual Network '$($spokePeeringParameters.Groups[1].Value)'"
                                            # Virtual Network Peering
                                            $workflowTask = [PSCustomObject]@{
                                                "alwaysRun"        = $true
                                                "condition"        = "succeededOrFailed()"
                                                "continueOnError"  = $false
                                                "definitionType"   = "metaTask"
                                                "enabled"          = $true
                                                "inputs"           = @{ }
                                                "name"             = "Create Spoke/spoke to: $($spokeServiceConnection.data.subscriptionName) - $($spokePeeringParameters.Groups[1].Value)"
                                                "overrideInputs"   = @{ }
                                                "refName"          = ""
                                                "taskId"           = $taskGroupPeering.id
                                                "timeoutInMinutes" = 0
                                                "version"          = "$($taskGroupPeering.version.major).*"
                                            }
                                            ForEach ($taskGroupInput In $taskGroupPeering.inputs) {
                                                $taskGroupInputName = $taskGroupInput.name
                                                $workflowTask.inputs.$taskGroupInputName = $taskGroupInput.defaultValue
                                            }
                                            $workflowTask.inputs.SubscriptionFolderName = $SubscriptionName
                                            $workflowTask.inputs.VnetFolderName = $VirtualNetworkName
                                            $workflowTask.inputs.SourceServiceEndpoint = $ServiceConnection.id
                                            $workflowTask.inputs.SourcePeerFileName = "VnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"
                                            $workflowTask.inputs.DestinationServiceEndpoint = $spokeServiceConnection.id
                                            $workflowTask.inputs.DestinationPeerFileName = "PeerVnetPeering$($spokePeeringParameters.Groups[1].Value).parameters.json"
                                            $stage.deployPhases[0].workflowTasks += $workflowTask
                                        }
                                        Else {
                                            Write-Error "No Service Connection found with subscriptionId '$($spokePeeringParameters.Groups[3].Value)' and starting with 'devops-azure-'"
                                        }
                                    }
                                    Else {
                                        Write-Error "The file '$($filePathSpokePeering)' or '$($filePathPeerSpokePeering)' doesn't exists within the branch '$($BranchName)'"
                                    }
                                }
                                Else {
                                    $i--
                                    Break
                                }
                            }
                        }
                    }
                }
                Else {
                    Write-Error "Readme file has no contents"
                }

                If ($null -ne ($virtualNetworkJson.parameters.subnetName.value | Where-Object -FilterScript { $_.ToLower().StartsWith("aks") })) {
                    If ($null -eq ($stage.deployPhases[0].workflowTasks | Where-Object -FilterScript { $_.name -eq 'Assign Enforce Subnet-NSG-RT relationship Policy' })) {
                        Write-Warning "An AKS subnet exists, but not the task 'Assign Enforce Subnet-NSG-RT relationship Policy'"
                    }
                }

                # Start sorting the Stages
                $orderNames = [System.Collections.Specialized.ListDictionary]::new()
                $orderEnvironments = [System.Collections.Specialized.ListDictionary]::new()
                $orderRemoves = [System.Collections.Specialized.ListDictionary]::new()
                $regexEnvironment = [System.Text.RegularExpressions.Regex]::new("(.*)-(e|d|t|a|p)-vnet.*", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $regexRemove = [System.Text.RegularExpressions.Regex]::new(".*(remove).*", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

                $sortExpression = @{
                    "Expression" = { If ($_.name -match '(.*)-(e|d|t|a|p)-vnet.*') { $Matches[1], @("e", "d", "t", "a", "p").IndexOf($Matches[2]) } }
                    "Ascending"  = $true
                }
                $i = 1
                ForEach ($environment In ($releasePipeline.environments | Where-Object -FilterScript { $regexRemove.IsMatch($_.name) -eq $false -and $RegexEnvironment.IsMatch($_.name) -eq $false } ) | Sort-Object -Property name) {
                    $orderNames.Add($environment.name, $i)
                    $i++
                }
                ForEach ($environment In ($releasePipeline.environments | Where-Object -FilterScript { $regexRemove.IsMatch($_.name) -eq $false -and $RegexEnvironment.IsMatch($_.name) -eq $true } ) | Sort-Object -Property $sortExpression) {
                    $orderEnvironments.Add($environment.name, $i)
                    $i++
                }
                ForEach ($environment In ($releasePipeline.environments | Where-Object -FilterScript { $regexRemove.IsMatch($_.name) -eq $true } ) | Sort-Object -Property name) {
                    $orderRemoves.Add($environment.name, $i)
                    $i++
                }

                For ($i = 0; $i -lt $releasePipeline.environments.Count; $i++) {
                    If ($orderNames.Contains($releasePipeline.environments[$i].name)) {
                        If ($releasePipeline.environments[$i].rank -ne $orderNames.Item($releasePipeline.environments[$i].name)) {
                            $releasePipeline.environments[$i].rank = $orderNames.Item($releasePipeline.environments[$i].name)
                        }
                    }
                    ElseIf ($orderEnvironments.Contains($releasePipeline.environments[$i].name)) {
                        If ($releasePipeline.environments[$i].rank -ne $orderEnvironments.Item($releasePipeline.environments[$i].name)) {
                            $releasePipeline.environments[$i].rank = $orderEnvironments.Item($releasePipeline.environments[$i].name)
                        }
                    }
                    ElseIf ($orderRemoves.Contains($releasePipeline.environments[$i].name)) {
                        If ($releasePipeline.environments[$i].rank -ne $orderRemoves.Item($releasePipeline.environments[$i].name)) {
                            $releasePipeline.environments[$i].rank = $orderRemoves.Item($releasePipeline.environments[$i].name)
                        }
                    }
                }
                # End of sorting the Stages
                #$releasePipeline | ConvertTo-Json -Depth 100
                Write-Host "Sorting of the stages:"
                ForEach ($environment In ($releasePipeline.environments | Sort-Object -Property rank)) {
                    If ($environment.name -eq "$($SubscriptionName): $($virtualNetworkJson.parameters.vnetName.value)") {
                        "* $($environment.rank.ToString().PadLeft(2, ' ')) - $($environment.name)"
                    }
                    Else {
                        "  $($environment.rank.ToString().PadLeft(2, ' ')) - $($environment.name)"
                    }
                }
                If ($ValidateOnly.IsPresent -eq $false) {
                    if($BuildAgent){
                        $result = 'y'
                    }else{
                        $result = Read-Host -Prompt "Create/update Stage (y/n)"
                    }

                    If ($result -eq 'y') {
                        $uri = "$($baseUriVsrmProject)/_apis/release/definitions?api-version=5.1"
                        Write-Host "Update the Release Pipeline"
                        $result = Invoke-RestMethod -Uri $uri -Method Put -Body ($releasePipeline | ConvertTo-Json -Depth 100 -Compress) -Headers $headers -UseBasicParsing
                        Write-Host "Release Pipeline '$($result.name)' has been updated"
                    }
                }
                Else {
                    Write-Host "ValidateOnly is specified, no changes will be applied."
                }
            }
            Else {
                Write-Error "No Release Pipeline found with the name 'Foundation-Networking-$($SubscriptionName)'"
            }
        }
        Else {
            Write-Error "Failed to convert the 'vnet.parameters.json' file"
        }
    }
    Else {
        Write-Error "The file '$ArtifactsDirectoryPath\vnet.parameters.json' doesn't exists in the $($BranchName) branch"
    }
}
Else {
    Write-Error "Azure DevOps Project '$($ProjectName)' not found within Organization '$($OrganizationName)'"
}
