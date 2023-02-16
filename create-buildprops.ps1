param (
    [Parameter(Mandatory = $True)] [string] $path,
    [Parameter()] [string] $targetFramework = "NET7.0",
    [Parameter()] [string] $implicitUsings = "enable",
    [Parameter()] [string] $nullable = "enable"
)


$buildPropsFileName = "$($path)/Directory.build.props"
$projectFileItems = Get-ChildItem -Path "$($path)" -Recurse -Filter "*.csproj"

function removeNode($projectNode, $xpathNode) {

    $node = $projectNode.selectSingleNode($xpathNode)
    if ($null -eq $node) {
        return;
    }

    $parentNode = $node.ParentNode
    if ($null -eq $parentNode) {
        "Strangely enough we're missing a parent node for '$($xpathNode)'"
        return;
    }

    $parentNode.removeChild($node) | Out-Null

    # Check if the parent can be removed also
    if ($parentNode.ChildNodes.Count -eq 0) {
        $parentsParentNode = $parentNode.ParentNode
        if ($null -ne $parentsParentNode) {
            $parentsParentNode.removeChild($parentNode) | Out-Null
        }
    }
}

foreach ($projectFile in $projectFileItems) {
    $projectFile.FullName
    $projectXml = [xml] (Get-Content -Path "$($projectFile.FullName)")

    removeNode $projectXml "//TargetFramework"
    removeNode $projectXml "//ImplicitUsings"
    removeNode $projectXml "//Nullable"

    $projectXml.save($projectFile.FullName)
}


# Unfortunately, `$someObject |  ConvertTo-Xml` does not do what I want :)
$buildProps = @"
<Project>
    <PropertyGroup>
        <TargetFramework>$($targetFramework)</TargetFramework>
        <ImplicitUsings>$($implicitUsings)</ImplicitUsings>
        <Nullable>$($nullable)</Nullable>
    </PropertyGroup>
</Project>
"@

Set-Content -Path "$($buildPropsFileName)" -Value "$($buildProps)"

"Wrote $($buildPropsFileName)"