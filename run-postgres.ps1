param (
    [Parameter(Mandatory = $False)]
    [switch] $pullImage = $False
)

if ($pullImage) { 
    docker pull postgres
}

docker run --name dev-postgres -e "POSTGRES_PASSWORD=Hello@W0rld" -p 5432:5432 -d postgres