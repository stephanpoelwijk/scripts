param (
    [Parameter(Mandatory = $True)]
    [string] $tableNames,
    [Parameter()]
    [string] $connectionString = "UseDevelopmentStorage=true"
)

$tableNamesArray = [array] $tableNames.split(",").trim()

foreach ($tableName in $tableNamesArray) {
    Write-Host -NoNewLine "Creating table $($tableName)..."

    $result = az storage table create --connection-string $connectionString --name $tableNAme.toLower() | ConvertFrom-Json
    if ($result.created) {
        "Created."
    }
    else {
        "Failed."
    }
}