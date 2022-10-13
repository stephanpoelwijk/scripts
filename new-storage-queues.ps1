param (
    [Parameter(Mandatory = $True)]
    [string] $queueNames,
    [Parameter()]
    [string] $connectionString = "UseDevelopmentStorage=true"
)

$queueNamesArray = [array] $queueNames.split(",").trim()

foreach ($queueName in $queueNamesArray) {
    Write-Host -NoNewLine "Creating queue $($queueName)..."

    $result = az storage queue create --connection-string $connectionString --name $queueName.toLower() | ConvertFrom-Json
    if ($result.created) {
        "Created."
    }
    else {
        "Failed."
    }
}