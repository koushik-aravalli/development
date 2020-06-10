<#
.DESCRIPTION
    This script allows a Item such as a PBI, Task to be created or updated within Azure DevOps.

.PARAMETER OrganizationName <String>
    The Azure DevOps Organization name.

.PARAMETER ProjectName <String>
    The Azure DevOps Project name.

.PARAMETER TeamName <String>
    The Team Name to create to work item for.

.PARAMETER ItemTypeName <String>
    Item type to create.

.PARAMETER ItemWorkType <String>
    Item type to create.

.PARAMETER ItemTitle [String]
    Item title. This item is mandatory, if no title is specified no item will be created.
    This is implemented to skip the creation of an Item when no ItemTitle is specified.

.PARAMETER ItemAreaPath [String]
    Item area path. Optional value, if not specified default Team Area is used.

.PARAMETER ItemTeamProject [String]
    Item project. Optional value, if not specified default Project is used.

.PARAMETER ItemIteration [String]
    Optional parameter to specify the iteration. If not specified the Item is placed on the back log.

.PARAMETER ItemPriority <Int32>
    Priority in a range of 1 to 3 where 1 is the highest priority. Default priority is 2.

.PARAMETER ItemEffort <Int32>
    Optional effort item.

.PARAMETER ItemDescription <String>
    Optional description of the item. The value is a Json string.

.PARAMETER ItemAcceptanceCriteria <String>
    Optional acceptance criteria. The value is a Json string.

.PARAMETER ItemParentId <Int32>
    Optional the parent item.

.PARAMETER ItemRelatedIds <Int32[]>
    Optional the related item(s).

.PARAMETER ItemPredecessorIds <Int32[]>
    Optional the predecessor item(s).

.PARAMETER ItemSuccessorIds <Int32[]>
    Optional the successor item(s)

.PARAMETER ItemState <String>
    The state of the item. Default is new.

.PARAMETER ItemAssignTo [String]
    Optional to specify to who the Item is assigned to

.PARAMETER ItemTags [String[]]
    Optional tag(s) to add/update. Default is none.

.PARAMETER UsersToNotify [String[]]
    Optional array of users to notify in the discussion field.

.PARAMETER UsersToNotifyPartOfTeam [Bool]
    Optinal value to specify if the users to notify must also be part of the team. Default value is true.

.PARAMETER ValidateOnly
    Specify to only perform a test run

.PARAMETER SuppressNotifications
    When specified there are no notifictations send.

.PARAMETER PersonalAccessToken [String]
    Personal Access Token with the following permissions (if not specified the System AccessToken is used):
    Project and Team
        Read
    Work Items
        Read & write
#>
[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $true)][String] $OrganizationName,
    [Parameter(Mandatory = $true)][String] $ProjectName,
    [Parameter(Mandatory = $true)][String] $TeamName,
    [Parameter(Mandatory = $true)][ValidateSet('Epics', 'Features', 'Backlog items', 'User Stories')][String] $ItemTypeName = 'Backlog items',
    [Parameter(Mandatory = $true)][ValidateSet('Bug', 'Code Review Request', 'Code Review Response', 'Epic', 'Feature', 'Feedback Request', 'Feedback Response', 'Impediment', 'Issue', 'Product Backlog Item', 'Shared Parameter', 'Shared Steps', 'Task', 'Test Case', 'Test Plan', 'Test Suite', 'User Story')][String] $ItemWorkType = 'Product Backlog Item',
    [Parameter(Mandatory = $false)][String] $ItemTitle = '',
    [Parameter(Mandatory = $false)][String] $ItemAreaPath = '',
    [Parameter(Mandatory = $false)][String] $ItemTeamProject = '',
    [Parameter(Mandatory = $false)][String] $ItemIteration = '',
    [Parameter(Mandatory = $false)][ValidateSet(1, 2, 3)][Int32] $ItemPriority = 2,
    [Parameter(Mandatory = $false)][Int32] $ItemEffort = 0,
    [Parameter(Mandatory = $false)][String] $ItemDescription = '',
    [Parameter(Mandatory = $false)][String] $ItemAcceptanceCriteria = '',
    [Parameter(Mandatory = $false)][Int32] $ItemParentId,
    [Parameter(Mandatory = $false)][Int32[]] $ItemRelatedIds = @(),
    [Parameter(Mandatory = $false)][Int32[]] $ItemPredecessorIds = @(),
    [Parameter(Mandatory = $false)][Int32[]] $ItemSuccessorIds = @(),
    [Parameter(Mandatory = $false)][ValidateSet('Active', 'Approved', 'Closed', 'Committed', 'Done', 'New', 'Removed', 'Resolved')][String] $ItemState = 'New',
    [Parameter(Mandatory = $false)][String] $ItemAssignTo = '',
    [Parameter(Mandatory = $false)][String[]] $ItemTags = @(),
    [Parameter(Mandatory = $false)][String[]] $UsersToNotify = @(),
    [Parameter(Mandatory = $false)][Bool] $UsersToNotifyPartOfTeam = $true,
    [Parameter(Mandatory = $false)][Switch] $ValidateOnly,
    [Parameter(Mandatory = $false)][Switch] $SuppressNotifications,
    [Parameter(Mandatory = $false)][String] $PersonalAccessToken
)

$ErrorActionPreference = 'Stop'

If ([System.String]::IsNullOrWhiteSpace($ItemTitle)) {
    Write-Warning "No ItemTitle specified, exit script"
    Exit 0
}

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

Write-Output "Input parameters"
Write-Output "OrganizationName        : $($OrganizationName)"
Write-Output "ProjectName             : $($ProjectName)"
Write-Output "TeamName                : $($TeamName)"
Write-Output "ItemTypeName            : $($ItemTypeName)"
Write-Output "ItemWorkType            : $($ItemWorkType)"
Write-Output "ItemTitle               : $($ItemTitle)"
Write-Output "ItemAreaPath            : $($ItemAreaPath)"
Write-Output "ItemTeamProject         : $($ItemTeamProject)"
Write-Output "ItemIteration           : $($ItemIteration)"
Write-Output "ItemPriority            : $($ItemPriority)"
Write-Output "ItemEffort              : $($ItemEffort)"
Write-Output "ItemDescription         : $($ItemDescription)"
Write-Output "ItemAcceptanceCriteria  : $($ItemAcceptanceCriteria)"
Write-Output "ItemParentId            : $($ItemParentId)"
Write-Output "ItemRelatedIds          : $([System.String]::Join(', ', $ItemRelatedIds))"
Write-Output "ItemPredecessorIds      : $([System.String]::Join(', ', $ItemPredecessorIds))"
Write-Output "ItemSuccessorIds        : $([System.String]::Join(', ', $ItemSuccessorIds))"
Write-Output "ItemState               : $($ItemState)"
Write-Output "ItemAssignTo            : $($ItemAssignTo)"
Write-Output "ItemTags                : $([System.String]::Join("; ", $ItemTags))"
Write-Output "UsersToNotify           : $([System.String]::Join("; ", $UsersToNotify))"
Write-Output "UsersToNotifyPartOfTeam : $($UsersToNotifyPartOfTeam)"
Write-Output "ValidateOnly            : $($ValidateOnly)"
Write-Output "SuppressNotifications   : $($SuppressNotifications)"
Write-Output ""

$resultWorkItemId = 0

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
    Write-Output "Project '$($project.name)' exists"
    $baseUriProject = "$($baseUri)/$($project.id)"
    $uri = "$($baseUri)/_apis/projects/$($project.id)/teams?api-version=5.1"
    $teams = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    If ($team = ($teams.value | Where-Object -FilterScript { $_.name -eq $TeamName })) {
        $baseUriTeam = "$($baseUriProject)/$($team.id)"
        If (![System.String]::IsNullOrWhiteSpace($ItemIteration)) {
            Write-Output "Retrieve iteration '$($ItemIteration)'"
            If ($ItemIteration -eq 'current') {
                $uri = "$($baseUriTeam)/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=5.1"
                $iterations = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                If ($iterations.count -eq 1) {
                    $iteration = $iterations.value[0]
                }
                Else {
                    Write-Error "Current iteration not found"
                }
            }
            Else {
                $uri = "$($baseUriTeam)/_apis/work/teamsettings/iterations?api-version=5.1"
                $iterations = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                $iteration = $iterations.value | Where-Object -FilterScript { $_.name -eq $ItemIteration }
            }
            If ($null -ne $iteration) {
                Write-Output "Found iteration '$($iteration.name)' within '$($iteration.path)'"
            }
            Else {
                Write-Error "Iteration '$($ItemIteration)' not found"
            }
        }
    }
    Else {
        Write-Error "Team '$($TeamName)' not found within the project '$($project.name)'"
    }

    $uri = "$($baseUriProject)/_apis/wit/workitemtypes/$($ItemWorkType)?api-version=5.1"
    Write-Output "Validate work item type exists '$($ItemWorkType)'"
    Try {
        If ($result = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing) {
            Write-Output "Found work item type '$($ItemWorkType)'"
        }
    }
    Catch {
        Write-Output "Work item type '$($ItemWorkType)' not found"
        $uri = "$($baseUriProject)/_apis/wit/workitemtypes?api-version=5.1"
        $result = Invoke-WebRequest -Uri $uri -Method Get -Headers $headers -UseBasicParsing
        $regEx = [System.Text.RegularExpressions.Regex]::new("{`"name`":`"([A-Za-z0-9- ]*)`"")
        $workItemTypes = $regEx.Matches($result.Content) | ForEach-Object { $_.Groups[1].Value } | Sort-Object | Group-Object
        Write-Error "Item '$($ItemWorkType)' not found within: $([System.String]::Join(', ', $workItemTypes.Name))"
    }
    $uri = "$($baseUriProject)/_apis/work/boards?api-version=5.1"
    $itemTypes = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
    If ($itemType = ($itemTypes.value | Where-Object -FilterScript { $_.name -eq $ItemTypeName })) {
        If ([System.String]::IsNullOrWhiteSpace($ItemAreaPath)) {
            Write-Output "No area path specified, find the default area path for team '$($team.name)'"
            $uri = "$($baseUriTeam)/_apis/work/teamsettings/teamfieldvalues?api-version=5.1"
            $teamFieldValues = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            $ItemAreaPath = $teamFieldValues.defaultValue
            Write-Output "Using default Team Area Path '$($teamFieldValues.defaultValue)' for team '$($team.name)'"
        }
        Else {
            Write-Output "Validate area path '$($ItemAreaPath)', current validation only for the active team '$($team.name)'"
            $uri = "$($baseUriTeam)/_apis/work/teamsettings/teamfieldvalues?api-version=5.1"
            $teamFieldValues = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            If ($TeamFieldValue = ($teamFieldValues.values | Where-Object -FilterScript { $_.value -eq $ItemAreaPath })) {
                $ItemAreaPath = $TeamFieldValue.value
                Write-Output "Found area path '$($ItemAreaPath)'"
            }
            Else {
                Write-Error "Failed to find the area path '$($ItemAreaPath)'"
            }
        }

        If (@($UsersToNotify).Count -gt 0 -Or [System.String]::IsNullOrWhiteSpace($ItemAssignTo) -eq $false) {
            $uri = "https://vsaex.dev.azure.com/$($OrganizationName)/_apis/userentitlements?top=10000&api-version=5.1-preview.2"
            $users = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            If ($users.totalCount -gt 10000) {
                Write-Host "##vso[task.logissue type=error]There are $($users.totalCount.ToString()) users while only the first 10000 are retrieved. No paging exists within api-version 5.1."
            }
        }

        $bodyItems = @()
        $existingItemFound = $false
        $workItemId = 0
        If (![System.String]::IsNullOrWhiteSpace($ItemParentId) -and $ItemParentId -gt 0) {
            $uri = "$($baseUriProject)/_apis/wit/workitems/$($ItemParentId)?`$expand=relations&api-version=5.1"
            $parentPBI = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
            #$ItemDescriptionJson = $ItemDescription | ConvertFrom-Json
            #$ItemDescriptionJson = $ItemDescriptionJson.Replace('<br />', '<br>')
            ForEach ($parentPBILink In ($parentPBI.relations | Where-Object -FilterScript { $_.rel -eq 'System.LinkTypes.Hierarchy-Forward' })) {
                $workItem = Invoke-RestMethod -Uri "$($parentPBILink.url)?api-version=5.1" -Method Get -Headers $headers -UseBasicParsing
                If ($workItem.fields.'System.Title' -eq $ItemTitle) {
                    $existingItemFound = $true
                    $workItemId = $workItem.id
                    Write-Host "Found existing item with the title '$($workItem.fields.'System.Title')' and id $($workItemId)"
                    If (![System.String]::IsNullOrWhiteSpace($ItemDescription)) {
                        If ($workItem.fields.'System.Description' -ne $ItemDescription) {
                            $bodyItem = [PSCustomObject]@{
                                "op"    = "add"
                                "path"  = "/fields/System.Description"
                                "from"  = $null
                                "value" = $ItemDescription
                            }
                            $bodyItems += $bodyItem
                        }
                    }
                    Break
                }
            }
        }

        If (!$existingItemFound) {
            # System.TeamProject
            If (![System.String]::IsNullOrWhiteSpace($ItemTeamProject)) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/System.TeamProject"
                    "from"  = $null
                    "value" = $ItemTeamProject
                }
                $bodyItems += $bodyItem
            }
            # System.AreaPath
            $bodyItem = [PSCustomObject]@{
                "op"    = "add"
                "path"  = "/fields/System.AreaPath"
                "from"  = $null
                "value" = $ItemAreaPath
            }
            $bodyItems += $bodyItem
            # System.IterationPath
            If (![System.String]::IsNullOrWhiteSpace($ItemIteration)) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/System.IterationPath"
                    "from"  = $null
                    "value" = $iteration.path
                }
                $bodyItems += $bodyItem
            }
            # System.Title
            $bodyItem = [PSCustomObject]@{
                "op"    = "add"
                "path"  = "/fields/System.Title"
                "from"  = $null
                "value" = $ItemTitle
            }
            $bodyItems += $bodyItem
            # System.Description
            If (![System.String]::IsNullOrWhiteSpace($ItemDescription)) {
                #$ItemDescriptionJson = $ItemDescription | ConvertFrom-Json
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/System.Description"
                    "from"  = $null
                    "value" = $ItemDescription
                }
                $bodyItems += $bodyItem
            }
            # Microsoft.VSTS.TCM.ReproSteps
            If ($ItemWorkType -eq 'Bug') {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/Microsoft.VSTS.TCM.ReproSteps"
                    "value" = $ItemDescription
                }
                $bodyItems += $bodyItem
            }
            # Microsoft.VSTS.Common.AcceptanceCriteria
            If (![System.String]::IsNullOrWhiteSpace($ItemAcceptanceCriteria)) {
                $ItemAcceptanceCriteriaJson = $ItemAcceptanceCriteria | ConvertFrom-Json
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/Microsoft.VSTS.Common.AcceptanceCriteria"
                    "from"  = $null
                    "value" = $ItemAcceptanceCriteriaJson
                }
                $bodyItems += $bodyItem
            }
            # /relations/-System.LinkTypes.Hierarchy-Reverse
            If (![System.String]::IsNullOrWhiteSpace($ItemParentId) -and $ItemParentId -gt 0) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/relations/-"
                    "from"  = $null
                    "value" = @{
                        "rel" = "System.LinkTypes.Hierarchy-Reverse"
                        "url" = "$($baseUri)/_apis/wit/workItems/$($ItemParentId)"
                    }
                }
                $bodyItems += $bodyItem
            }
            # /relations/-System.LinkTypes.Related
            ForEach ($itemRelatedId In $ItemRelatedIds) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/relations/-"
                    "from"  = $null
                    "value" = @{
                        "rel" = "System.LinkTypes.Related"
                        "url" = "$($baseUri)/_apis/wit/workItems/$($itemRelatedId)"
                    }
                }
                $bodyItems += $bodyItem
            }
            # /relations/-System.LinkTypes.Dependency-Reverse
            ForEach ($itemPredecessorId In $ItemPredecessorIds) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/relations/-"
                    "from"  = $null
                    "value" = @{
                        "rel" = "System.LinkTypes.Dependency-Reverse"
                        "url" = "$($baseUri)/_apis/wit/workItems/$($itemPredecessorId)"
                    }
                }
                $bodyItems += $bodyItem
            }
            # /relations/-System.LinkTypes.Dependency-Forward
            ForEach ($itemSuccessorId In $ItemSuccessorIds) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/relations/-"
                    "from"  = $null
                    "value" = @{
                        "rel" = "System.LinkTypes.Dependency-Forward"
                        "url" = "$($baseUri)/_apis/wit/workItems/$($itemSuccessorId)"
                    }
                }
                $bodyItems += $bodyItem
            }
            # System.AssignedTo
            If (![System.String]::IsNullOrWhiteSpace($ItemAssignTo)) {
                If ($userItem = ($users.items | Where-Object -FilterScript { $_.user.principalName -eq $ItemAssignTo })) {
                    Write-Output "Found user '$($ItemAssignTo)' with displayName '$($userItem.user.displayName)' and id '$($userItem.id)'"
                    $bodyItem = [PSCustomObject]@{
                        "op"    = "add"
                        "path"  = "/fields/System.AssignedTo"
                        "from"  = $null
                        "value" = @{
                            "id"         = "$($userItem.id)"
                            "descriptor" = "$($userItem.user.descriptor)"
                        }
                    }
                    $bodyItems += $bodyItem
                }
                Else {
                    Write-Warning "No user found with principalName '$($ItemAssignTo)', item will not be assigned!"
                }
            }
            # System.Tags
            If (@($ItemTags).Count -gt 0) {
                $bodyItem = [PSCustomObject]@{
                    "op"    = "add"
                    "path"  = "/fields/System.Tags"
                    "from"  = $null
                    "value" = [System.String]::Join("; ", $ItemTags)
                }
                $bodyItems += $bodyItem
            }
            # System.History
            If (@($UsersToNotify).Count -gt 0) {
                $fyiUsers = @()

                If ($UsersToNotifyPartOfTeam) {
                    $uri = "$($baseUriTeam)/_apis/work/teamsettings/iterations/$($iteration.id)/capacities?api-version=5.1"
                    $teamMembers = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                }

                ForEach ($userToNotify In $UsersToNotify) {
                    Write-Output "Search for user '$($userToNotify)' to notify"
                    If ($userItems = ($users.items | Where-Object -FilterScript { $_.user.principalName -eq $userToNotify -or $_.user.mailAddress -eq $userToNotify })) {
                        Write-Output "Found $(@($userItems).Count) with the principalName or mailAddress with the value '$($userToNotify)'"
                        ForEach ($userItem In $userItems) {
                            If ($UsersToNotifyPartOfTeam) {
                                Write-Output "Search for team member with the id '$($userItem.id)'"
                                If ($teamMember = ($teamMembers.value | Where-Object -FilterScript { $_.teamMember.id -eq $userItem.id })) {
                                    Write-Output "Found team member with id '$($teamMember.teamMember.id)', get the storage key of the descriptor '$($userItem.user.descriptor)'"
                                    $uri = "https://vssps.dev.azure.com/$($OrganizationName)/_apis/graph/storagekeys/$($userItem.user.descriptor)?api-version=5.1-preview.1"
                                    $storageKey = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                                    $href = "<a href=`"#`" data-vss-mention=`"version:2.0,$($storageKey.value)`">@$($userItem.user.displayName)</a>"
                                    Write-Output "Found user '$($userToNotify)' with displayName '$($userItem.user.displayName)', id '$($userItem.id)' and storage key '$($storageKey.value)'"
                                    $fyiUsers += $href
                                }
                                Else {
                                    Write-Warning "No team member found with id '$($userItem.id)'"
                                }
                            }
                            Else {
                                Write-Output "Found user with id '$($userItem.id)', get the storage key of the descriptor '$($userItem.user.descriptor)'"
                                $uri = "https://vssps.dev.azure.com/$($OrganizationName)/_apis/graph/storagekeys/$($userItem.user.descriptor)?api-version=5.1-preview.1"
                                $storageKey = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                                $href = "<a href=`"#`" data-vss-mention=`"version:2.0,$($storageKey.value)`">@$($userItem.user.displayName)</a>"
                                Write-Output "Found user '$($userToNotify)' with displayName '$($userItem.user.displayName)', id '$($userItem.id)' and storage key '$($storageKey.value)'"
                                $fyiUsers += $href
                            }
                        }
                    }
                    Else {
                        Write-Warning "No user(s) found with principalName or mailAddress with the value '$($userToNotify)'"
                    }
                }
                If ($fyiUsers.Count -gt 0) {
                    $historyBody = "Fyi: $([System.String]::Join(', ', $fyiUsers))"
                    $bodyItem = [PSCustomObject]@{
                        "op"    = "add"
                        "path"  = "/fields/System.History"
                        "from"  = $null
                        "value" = $historyBody
                    }
                    $bodyItems += $bodyItem
                }
            }
        }

        If ($bodyItems.Count -gt 0) {
            # Create item
            $body = $bodyItems | ConvertTo-Json -Depth 100
            $body = $body.Replace("\u003c", "<").Replace("\u003e", ">").Replace("\u0026", "&").Replace("\u0027", "'")
            If ($bodyItems.Count -eq 1) {
                $body = "[$($body)]"
            }

            $uriItems = @("api-version=5.1")
            If (!$ValidateOnly) {
                If ($SuppressNotifications) {
                    $uriItems += "suppressNotifications=true"
                }
            }
            Else {
                $uriItems += "validateOnly=true"
            }

            $uriSuffix = [System.String]::Join('&', $uriItems)
            If ($existingItemFound) {
                $method = "Patch"
                $uri = "$($baseUriProject)/_apis/wit/workitems/$($workItemId)?$($uriSuffix)"
            }
            Else {
                $method = "Post"
                $uri = "$($baseUriProject)/_apis/wit/workitems/`$$ItemWorkType`?$($uriSuffix)"
            }

            Write-Output "Create/update item using uri '$($uri)'"
            If (!$ValidateOnly) {
                $result = Invoke-RestMethod -Uri $uri -Method $method -Body $body -Headers $headers -ContentType 'application/json-patch+json' -UseBasicParsing
                $resultWorkItemId = $result.id
                Write-Output "Item has been created/updated with id $($resultWorkItemId)"
                $result | ConvertTo-Json -Depth 100
                $bodyItems = @()
                If ($ItemState -ne 'New') {
                    Write-Output "Validate if ItemState '$($ItemState)' exists"
                    $uri = "$($baseUriTeam)/_apis/work/boards/$($itemType.name)/columns?api-version=5.1"
                    $itemStates = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -UseBasicParsing
                    If ($null -eq ($itemStates.value | Where-Object -FilterScript { $_.name -eq $ItemState })) {
                        Write-Error "ItemState '$($ItemState)' not found within: $([System.String]::Join(', ', $itemStates.value.name))"
                    }
                    Write-Output "Updated the 'System.State' from '$($result.fields.'System.State')' to '$($ItemState)'"
                    $bodyItem = [PSCustomObject]@{
                        "op"    = "add"
                        "path"  = "/fields/System.State"
                        "value" = $ItemState
                    }
                    $bodyItems += $bodyItem
                }
                If (@($bodyItems).Count -gt 0) {
                    $body = $bodyItems | ConvertTo-Json -Depth 100
                    $body = $body.Replace("\u003c", "<").Replace("\u003e", ">").Replace("\u0026", "&").Replace("\u0027", "'")
                    If ($bodyItems.Count -eq 1) {
                        $body = "[$($body)]"
                    }
                    If ($SuppressNotifications) {
                        $uri = "$($result.url)?suppressNotifications=true&api-version=5.1"
                    }
                    Else {
                        $uri = "$($result.url)?api-version=5.1"
                    }
                    Write-Output "Update item using uri '$($uri)'"
                    If ($updateResult = Invoke-RestMethod -Uri $uri -Method Patch -Body $body -Headers $headers -ContentType 'application/json-patch+json' -UseBasicParsing) {
                        Write-Output "Updated the item $($updateResult.id) ($($updateResult.fields.'System.Title')) to the state '$($updateResult.fields.'System.State')'"
                    }
                    Else {
                        Write-Error "Failed to update the item  $($updateResult.id) ($($updateResult.fields.'System.Title')) to the state '$($updateResult.fields.'System.State')'"
                    }
                }
                Write-Output "Completed creating/updating Work Item Id $($resultWorkItemId)"
            }
            Else {
                Write-Output "Creation/updating of the Work Item is not enabled, only validation performed with the following result:"
                $result = Invoke-RestMethod -Uri "$uri&validateOnly=true" -Method $method -Body $body -Headers $headers -ContentType 'application/json-patch+json' -UseBasicParsing
                $result | ConvertTo-Json -Depth 100
            }
        }
    }
    Else {
        Write-Error "The ItemTypeName '$($ItemTypeName)' is not found within the Project '$($project.name)', valid types are: $([System.String]::Join(', ', $itemTypes.value.name))"
    }
}
Else {
    Write-Error "The Project '$($ProjectName)' doesn't or no access to"
}
