param (
    [Parameter(Mandatory = $True)] [string] $appName,
    [Parameter()] [switch] $makeMeOwner = $False,
    [Parameter()] [string] $rolesFileName
)

# Make a'sure that we're in Azure
$azCommandOutput = (az ad signed-in-user show 2>&1) | Out-String
if ($azCommandOutput.contains('Interactive authentication is needed')) {
    Write-Host "Not logged into Azure - Quitting"
    return
}
else {
    Write-Host "Logged into Azure"
}

$currentUser = az ad signed-in-user show | ConvertFrom-Json
Write-Host "Running as $($currentUser.displayName) ($($currentUser.id))"

# Set common variables
$environment = 'dev'
$appName = $appName.ToLower()
$fullAppName = "$($environment)-$($appName)"

# Some parameter checking
if ($rolesFileName -ne '' -and (!(Test-Path -Path $rolesFileName))) {
    Write-Host "Could not find roles file $($rolesFileName)"
    return
}

# Off we go
$existingAppList = [array] (az ad app list --display-name "$($fullAppName)" | ConvertFrom-Json)
if ($existingAppList.length -eq 0) {
    Write-Host "Creating app registration for $($appName) ($($fullAppName))"

    $existingAppList = [array] (az ad app create --display-name "$($fullAppName)" | ConvertFrom-Json)
}
else {
    Write-Host "Updating app registration for $($appName) ($($fullAppName))"
}

$appRegistration = $existingAppList[0]

Write-Host "App Registration: $($appRegistration.displayName) ClientId: $($appRegistration.appId) ObjectId: $($appRegistration.id)"

if ($makeMeOwner) { 
    Write-Host "Make $($currentUser.displayName) ($($currentUser.id)) owner"
    az ad app owner add --id $($appRegistration.id) --owner-object-id $($currentUser.id)
}

Write-Host "Setting common parameters"
az ad app update `
    --id $appRegistration.id `
    --identifier-uris "api://$($fullAppName)/api"

az rest --method PATCH `
    --headers "Content-type=application/json" `
    --uri "https://graph.microsoft.com/v1.0/applications/$($appRegistration.id)" `
    --body '{"api":{"requestedAccessTokenVersion": 2}}'


if ($rolesFileName -ne '') {

    $rolesToDisable = @()

    # TODO: Only disable the roles that are not in the roles file so that existing 
    #       AD group assignments do not disappear

    foreach ($appRole in $appRegistration.appRoles) {
        $appRole.description
        $appRole.isEnabled = $False
        $rolesToDisable += $appRole
    }

    ConvertTo-Json $rolesToDisable -Depth 2 -Compress | az ad app update `
        --id $appRegistration.id `
        --app-roles "@-"

    Write-Host "Update available roles"
    az ad app update `
        --id $appRegistration.id `
        --app-roles "`@$($rolesFileName)"
}


Write-Host "Done"