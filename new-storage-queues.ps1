param (
    [Parameter(Mandatory = $True)]
    [string] $queueNames,
    [Parameter()]
    [string] $connectionString = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
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