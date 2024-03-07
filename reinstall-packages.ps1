param (
    [Parameter()]
    [string] $folder = ".",

    [Parameter()]
    [switch] $includePrerelease = $False,

    [Parameter()]
    [switch] $force = $False
)
$projectFileNames = Get-ChildItem -Include *.csproj -Recurse -Path $folder

foreach ($projectFileName in $projectFileNames) {
    Write-Host "Processing $($projectFileName)"

    $projectXml = [xml] (Get-Content "$($projectFileName)")
    $packageReferenceNodes = $projectXml.SelectNodes("//PackageReference");

    foreach ($node in $packageReferenceNodes) {
        $packageName = $node.Attributes["Include"].Value
        $packageVersion = $node.Attributes["Version"].Value

        "Package $($packageName) -> $($packageVersion)"

        if ($force) {
            if ($includePrerelease) {
                dotnet add "$($projectFileName)" package "$($packageName)" --prerelease
            }
            else {
                dotnet add "$($projectFileName)" package "$($packageName)"
            }
        }
    }
}