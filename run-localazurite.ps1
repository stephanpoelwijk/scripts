param (
    [Parameter()]
    [string] $localDataFolder = ".azurite"
)

function getWslPath ($folderItem) {

    # Converts the drive part to lowercase and flips '\' to '/'
    $driveLetter = $folderItem.Root.Name.Replace(":\", "").toLower()
    $directoryName = $folderItem.FullName.Replace("\", "/").Substring($fullLocalDataFolder.Root.Name.Length)
    
    "//$driveLetter/$directoryName"
}

if (!(Test-Path -Path $localDataFolder)) {
    "Creating folder $($localDataFolder)"
    New-Item -Path $localDataFolder -ItemType Directory
}

$fullLocalDataFolder = Get-Item "$($localDataFolder)";
$localDataFolderName = getWslPath $fullLocalDataFolder

"`nLocal development connection string:"
"UseDevelopmentStorage=true"
"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;"

docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 --mount "type=bind,source=$localDataFolderName,target=/data" mcr.microsoft.com/azure-storage/azurite
