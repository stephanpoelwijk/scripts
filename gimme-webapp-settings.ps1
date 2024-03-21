param (
    [Parameter(Mandatory = $True)] [string] $resourceGroupName,
    [Parameter(Mandatory = $True)] [string] $webAppName,
    [Parameter()] [string] $namePartSeparator = ":"
)

$appSettings = az webapp config appsettings list --resource-group "$($resourceGroupName)" --name "$($webAppName)" | ConvertFrom-Json

$devAppSettings = @{}

foreach ($appSetting in $appSettings) {
    $parts = [array]$appSetting.name -split $namePartSeparator
    $partIndex = 0
    $currentObject = $devAppSettings

    while ($partIndex -lt $parts.length) {

        $part = $parts[$partIndex]
        $remainingParts = $parts.length - $partIndex

        if ($remainingParts -eq 1) {
            $currentObject[$part] = $appSetting.value
        }
        else {
            if ($null -eq $currentObject.$part) {
                $currentObject.$part = @{}
            }
            $currentObject = $currentObject.$part
        }

        $partIndex++
    }
}

$devAppSettings | ConvertTo-Json -Depth 10
