param (
    [Parameter(Mandatory = $True)] [string] $appName,
    [Parameter()] [switch] $makeMeOwner = $False,
    [Parameter()] [string] $rolesFileName,
    [Parameter()] [string] $roleAssignmentsFileName
)

# Loads of ids for the same object are floating around in here. The documentation is pretty clear what to pick up:
#
# https://learn.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignedto?view=graph-rest-1.0&tabs=http

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

if ($roleAssignmentsFileName -ne '' -and (!(Test-Path -Path $roleAssignmentsFileName))) {
    Write-Host "Could not find role assignments file $($roleAssignmentsFileName)"
    return;
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

function makeMeOwner {
    param(
        [Parameter()] [object] $appRegistration,
        [Parameter()] [object] $currentUser,
        [Parameter()] [boolean] $makeMeOwner
    )
    if ($makeMeOwner) { 
        Write-Host "Make $($currentUser.displayName) ($($currentUser.id)) owner"
        az ad app owner add --id $($appRegistration.id) --owner-object-id $($currentUser.id)
    }
}

function setCommonParameters {
    param(
        [Parameter()] [object] $appRegistration,
        [Parameter()] [string] $appName
    )

    Write-Host "Setting common parameters"
    az ad app update `
        --id $appRegistration.id `
        --identifier-uris "api://$($fullAppName)/api"

    az rest --method PATCH `
        --headers "Content-type=application/json" `
        --uri "https://graph.microsoft.com/v1.0/applications/$($appRegistration.id)" `
        --body '{"api":{"requestedAccessTokenVersion": 2}}'
}

function updateRoles {
    param(
        [Parameter()] [object] $appRegistration,
        [Parameter()] [array] $configuredRoles
    )

    if ($configuredRoles.length -eq 0) {
        return;
    }

    Write-Host "Updating roles"
    $roles = @()
    foreach ($appRole in $appRegistration.appRoles) {
        $configuredRole = $configuredRoles | Where-Object { $_.value -eq $appRole.value } | Select-Object -First 1

        # Roles are always disabled (whether the role is updated or not). If the role is not disabled,
        # the error message "Permission (scope or role) cannot be deleted or updated unless disabled first."
        # will pop up.
        $appRole.isEnabled = $False

        if ($Null -eq $configuredRole) {
            Write-Host "Deleting $($appRole.displayName) ($($appRole.value))"
        }
        else {
            Write-Host "Updating $($appRole.displayName) ($($appRole.value))"
            $appRole.description = $configuredRole.description
            $appRole.displayName = $configuredRole.displayName

            $roles += $appRole
        }
    }

    foreach ($configuredRole in $configuredRoles) {
        $existingRole = $appRegistration.appRoles | Where-Object { $_.value -eq $configuredRole.value } | Select-Object -First 1
        if ($Null -eq $existingRole) {
            Write-Host "Adding $($configuredRole.displayName) ($($configuredRole.value))"
            $roleId = ([Guid]::NewGuid()).guid
            $roles += @{
                "id"                 = "$($roleId)"
                "allowedMemberTypes" = @(
                    "User"
                )
                "description"        = $configuredRole.description
                "displayName"        = $configuredRole.displayName
                "isEnabled"          = $True
                "value"              = $configuredRole.value
            }
        }
    }

    Write-Host "Disabling roles & updating app registration"
    ConvertTo-Json $appRegistration.appRoles -Depth 2 -Compress | az ad app update `
        --id $appRegistration.id `
        --app-roles "@-"

    Write-Host "Enabling roles & updating app registration"
    foreach ($role in $roles) {
        $role.isEnabled = $True
    }

    Write-Host "Saving roles"
    ConvertTo-Json $roles -Depth 2 -Compress | az ad app update `
        --id $appRegistration.id `
        --app-roles "@-"
}

function ensureServicePrincipalExists() {
    param(
        [Parameter()] [object] $appRegistration
    )

    $enterpriseAppRegistrationOutput = (az ad sp show --id $($appRegistration.appId) 2>&1) | Out-String
    if ($enterpriseAppRegistrationOutput.contains('does not exist')) {
        Write-Host "Creating app service principal"
        az ad sp create --id $($appRegistration.appId) 2>&1 | Out-Null
    }
}

function assignRole() {
    param(
        [Parameter()] [string] $principalId,
        [Parameter()] [string] $resourceId,
        [Parameter()] [string] $roleId
    )

    $requestBody = @{
    
        "principalId" = $principalId
        "resourceId"  = $resourceId
        "appRoleId"   = $roleId
    }
    
    Write-Host "Assigning role. PrincipalId $($requestBody.principalId) ResourceId $($resourceId) RoleId $($requestBody.appRoleId)"

    $requestBody `
    | ConvertTo-Json -Compress -Depth 2 `
    | az rest --method POST `
        --headers "Content-type=application/json" `
        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipalId)/appRoleAssignedTo" `
        --body "@-" 2>&1

}

function removeRoleAssignment() {
    param(
        [Parameter()] [string] $assignmentId,
        [Parameter()] [string] $principalId,
        [Parameter()] [string] $resourceId,
        [Parameter()] [string] $roleId
    )

    Write-Host "Removing role. PrincipalId $($principalId) ResourceId $($resourceId) RoleId $($roleId) AssignmentId $($assignmentId)"

    az rest --method DELETE `
        --headers "Content-type=application/json" `
        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipalId)/appRoleAssignedTo/$($assignmentId)"
}

function updateRoleAssignments() {
    param(
        [Parameter()] [object] $appRegistration,
        [Parameter()] [array] $configuredRoleAssignments
    )

    $enterpriseAppRegistration = az ad sp show --id $($appRegistration.appId) | ConvertFrom-Json
    $servicePrincipalId = $enterpriseAppRegistration.id

    Write-Host "App Registration: $($appRegistration.displayName) ClientId: $($appRegistration.appId) ServicePrincipalId: $($servicePrincipalId)"

    $roleAssignments = @()

    foreach ($roleAssignment in $configuredRoleAssignments) {
        $role = $enterpriseAppRegistration.appRoles | Where-Object { $_.value -eq $roleAssignment.roleName } | Select-Object -First 1
        if ($null -eq $role) {
            Write-Host "Could not find role $($roleAssignment.roleName)"
            continue
        }

        foreach ($groupName in $roleAssignment.groups) {
            $group = ([array] (az ad group list --filter "displayName eq '$($groupName)'" | ConvertFrom-Json -Depth 3)) | Select-Object -First 1
            if ($Null -eq $group) {
                Write-Host "Could not find group $($groupName)"
                continue
            }

            Write-Host "Assigning group $($userName) to $($role.displayName)"

            $roleAssignments += @{
                "principalId" = $group.id
                "resourceId"  = $servicePrincipalId
                "appRoleId"   = $role.id
            }
        }

        foreach ($userName in $roleAssignment.users) {
            $user = ([array] (az ad user list --filter "userPrincipalName eq '$($userName)'" | ConvertFrom-Json -Depth 3)) | Select-Object -First 1
            if ($Null -eq $user) {
                Write-Host "Could not find user with userprincipal name $($userName)"
                return
            }

            Write-Host "Assigning user $($userName) to $($role.displayName)"

            $roleAssignments += @{
                "principalId" = $user.id
                "resourceId"  = $servicePrincipalId
                "appRoleId"   = $role.id
            }
        }
    }

    $existingRoleAssignments = [array] (az rest --method GET `
            --headers "Content-type=application/json" `
            --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipalId)/appRoleAssignedTo" `
        | ConvertFrom-Json)

    Write-Host "Deleting unnecessary role assignments (if any)"
    foreach ($existingRoleAssignment in $existingRoleAssignments) {
        $roleAssignment = $roleAssignments | Where-Object({ $_.principalId -eq $existingRoleAssignment.value.principalId -and $_.appRoleId -eq $existingRoleAssignment.value.appRoleId }) | Select-Object -First 1;
        if ($Null -eq $roleAssignment -and $null -ne $existingRoleAssignment.value.principalId) {
            removeRoleAssignment -assignmentId $existingRoleAssignment.value.id -principalId $existingRoleAssignment.value.principalId -resourceId $existingRoleAssignments.value.resourceId -roleId $existingRoleAssignments.value.appRoleId
        }
    }

    if ($roleAssignments.length -gt 0) {

        Write-Host "Creating role assignments"
        foreach ($roleAssignment in $roleAssignments) {
            $existingRoleAssignment = $existingRoleAssignments | Where-Object({ $_.value.principalId -eq $roleAssignment.principalId -and $_.value.appRoleId -eq $roleAssignment.appRoleId }) | Select-Object -First 1;
            if ($Null -ne $existingRoleAssignment) {
                Write-Host "Role assignment already exists for PrincipalId $($roleAssignment.principalId) and RoleId $($roleAssignment.appRoleId)"
                continue
            }

            assignRole -principalId $roleAssignment.principalId -resourceId $roleAssignment.resourceId -roleId $roleAssignment.appRoleId
        }
    }
}

function main() {
    makeMeOwner -appRegistration $appRegistration -currentUser $currentUser -makeMeOwner $makeMeOwner
    setCommonParameters -appRegistration $appRegistration -appName $fullAppName

    if ($rolesFileName -ne '') {
        $roles = [array] (Get-Content -Path $rolesFileName | ConvertFrom-Json -Depth 3)

        updateRoles -appRegistration $appRegistration -configuredRoles $roles
    }

    if ($roleAssignmentsFileName -ne '') {
        $roleAssignments = [array] (Get-Content -Path $roleAssignmentsFileName | ConvertFrom-Json -Depth 3)

        ensureServicePrincipalExists -appRegistration $appRegistration

        updateRoleAssignments -appRegistration $appRegistration -configuredRoleAssignments $roleAssignments
    }

    Write-Host "Done"

}
main
