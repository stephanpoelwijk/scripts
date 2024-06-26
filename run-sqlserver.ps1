param (
    [Parameter()]
    [string] $localDataFolder = ".azurite",

    [Parameter(Mandatory = $False)]
    [switch] $pullImage = $False
)

if ($pullImage) { 
    docker pull mcr.microsoft.com/mssql/server:2022-latest
}

docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=<Hello@W0rld>" -p 1433:1433 --name localsql -d mcr.microsoft.com/mssql/server:2022-latest