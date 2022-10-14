param (
    [Parameter(Mandatory = $True)]
    [string] $tableNames,
    [Parameter()]
    [string] $connectionString = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
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