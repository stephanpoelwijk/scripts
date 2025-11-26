param (
    [Parameter(Mandatory = $False)]
    [switch] $pullImage = $False
)

if ($pullImage) { 
    docker pull mysql:latest 
}

docker run -e MYSQL_ROOT_PASSWORD=my-secret-password -p 3306:3306 --name localmysql -d mysql
