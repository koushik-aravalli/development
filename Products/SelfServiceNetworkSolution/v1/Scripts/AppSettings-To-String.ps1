[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $AppSettingsLocation
)
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        If ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        If ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                Foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } 
        Elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            Foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } 
        Else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

$JsonContent = Get-Content $AppSettingsLocation | ConvertFrom-Json

$appsettings_map = $JsonContent.Values | ConvertTo-HashTable

$appsettings = ""
Foreach ($key in $appsettings_map.Keys) {
    $appsettings += "$($key)='$($appsettings_map[$key])' "
}

Write-Host "##vso[task.setvariable variable=appsettings;isOutput=true]$appsettings"