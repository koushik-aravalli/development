<#
    Search and Replace environment variables

    Example:
    .\Replace-Token.ps1 -RootDirectory C:\Users\C47321\Sources\Repos\ABNAMRO\Azure\PlatformNetworking\ProductTasksExtension\ProductTasks -TokenFile 'Invoke-TriggerFunction.ps1' -TokenPrefix '#{' -TokenSuffix '}#' -ReplaceValue 'e'
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String] $RootDirectory,

    [Parameter(Mandatory = $true)]
    [String] $TokenFile,

    [Parameter(Mandatory = $true)]
    [String] $TokenPrefix,

    [Parameter(Mandatory = $true)]
    [String] $TokenSuffix,    

    [Parameter(Mandatory = $true)]
    [String] $ReplaceValue
)


#region find TokenFiles
$TokenFiles = Get-ChildItem -Path $RootDirectory -Filter $TokenFile -Recurse
#endregion

#replace tokens
If (![System.String]::IsNullOrWhiteSpace($TokenFiles)) {
    Foreach ($File in $TokenFiles) {
        Write-Verbose -message ('TokenFile name: {0}' -f $File.FullName)
        (Get-Content -Path $($File.FullName)) -replace ('{0}.+\w{1}' -f $TokenPrefix, $TokenSuffix), $ReplaceValue | Set-Content -path $($File.FullName) -Force
    }
}
Else {
    Write-Error -Message ('No Token files found!')
}
#endregion