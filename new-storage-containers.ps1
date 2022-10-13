param (
    [Parameter(Mandatory = $True)]
    [string] $storageContainerNames,
    [Parameter()]
    [string] $connectionString = "UseDevelopmentStorage=true"
)

$storageContainerNamesArray = [array] $storageContainerNames.split(",").trim()

foreach ($storageContainerName in $storageContainerNamesArray) {
    Write-Host -NoNewLine "Creating storage container $($storageContainerName)..."

    $result = az storage container create --connection-string $connectionString --name $storageContainerName.toLower() | ConvertFrom-Json
    if ($result.created) {
        "Created."
    }
    else {
        "Failed."
    }
}