param (
    [Parameter(Mandatory = $True)] [string] $appName,
    [Parameter()] [string] $softwareZipFileName = '',
    [Parameter()] [string] $bicepDeploymentFileName = '',
    [Parameter()] [string] $bicepDeploymentParameterFileName = '',
    [Parameter()] [string] $location = 'westeurope',
    [Parameter()] [switch] $force = $False
)

# Make a'sure that we're in Azure
$azCommandOutput = (az ad signed-in-user show 2>&1) | Out-String
if ($azCommandOutput.contains('Interactive authentication is needed')) {
    Write-Host "Not logged into Azure"
}
else {
    Write-Host "Logged into Azure"
}

$currentUser = az ad signed-in-user show | ConvertFrom-Json
Write-Host "Running as $($currentUser.displayName) ($($currentUser.id))"

$currentSubscription = az account list | ConvertFrom-Json | Where-Object { $_.IsDefault -eq $True }
if ($null -eq $currentSubscription) { 
    Write-Host "Please set the default subscription by running 'az account set --subscription [SUBSCRIPTION_NAME]'"
    return;
}

Write-Host "Azure subscription $($currentSubscription.name) / Tenant $($currentSubscription.tenantId)"

# Set common variables
$environment = 'dev'
$appName = $appName.ToLower()
$deploymentGroupName = "dplres-$($environment)-$($appName)"
$resourceGroupName = "rg-$($environment)-$($appName)"
$tempBicepDeploymentParameterFileName = [System.IO.Path]::GetTempFileName();

# Resource names
$resourceParameters = [ordered]@{
    tenantId = $currentSubscription.tenantId;
    appName  = $appName;
    location = $location;
}

if ($bicepDeploymentParameterFileName -ne '') { 
    $bicepResourceParameters = (Get-Content -Path $bicepDeploymentParameterFileName) | ConvertFrom-Json
    foreach ($property in $bicepResourceParameters.psobject.properties) {
        Write-Host "Setting $($property.Name) to '$($property.Value)'"
        $resourceParameters[$property.Name] = $property.Value
    }
}

# Write out things for debugging purposes
Write-Host "`nResource Parameters"
$resourceParameters | ConvertTo-Json
Write-Host "`n"

# A couple of sanity checks
if (($bicepDeploymentFileName -ne '') -and (!(Test-Path -Path $bicepDeploymentFileName))) {
    Write-Host "Could not find the Bicep file '$($bicepDeploymentFileName)'"
    return;
}

if (($softwareZipFileName -ne '') -and (!(Test-Path -Path $softwareZipFileName))) {
    Write-Host "Could not find software file '$($softwareZipFileName)"
    return;
}

if (!$force) {
    Write-Host "Not actually deploying. Use the -force parameter to run everything"
    return
}

# Resource deployment
if ($bicepDeploymentFilename -ne '') {
    Write-Host "Creating resource deployment $($deploymentGroupName) from $($bicepDeploymentFileName)"

    $bicepParameters = [ordered] @{
        "`$schema"       = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        "contentVersion" = "1.0.0.0"
        "parameters"     = [ordered] @{}
    }

    foreach ($resourceParameterName in $resourceParameters.Keys) {
        $bicepParameters["parameters"]["$($resourceParameterName)"] = @{ 
            "value" = "$($resourceParameters[$resourceParameterName])" 
        } 
    }

    $bicepParameters | ConvertTo-Json | Out-File -FilePath $tempBicepDeploymentParameterFileName

    Write-Host "Deploy resource group"
    az group create --name $($resourceGroupName) --location $($location) | Out-Null

    Write-Host "Deploy resources"
    az deployment group create `
        --verbose `
        --name $($deploymentGroupName) `
        --resource-group $($resourceGroupName) `
        --template-file $($bicepDeploymentFileName) `
        --parameters "`@$($tempBicepDeploymentParameterFileName)"
}
else {
    Write-Host "Skipping resource deployment"
}

# Software deployment
if ($softwareZipFileName -ne '') {
    Write-Host "Deploying web application $($appName) to $($resourceGroupName)"
    az webapp deploy `
        --resource-group $($resourceGroupName) `
        --name $($appName) `
        --src-path $($softwareZipFileName)
}
else {
    Write-Host "Skipping software deployment"
}

# Clean up
if (Test-Path -Path $tempBicepDeploymentParameterFileName) {
    Write-Host "Removing temporary bicep parameter deployment filename $($tempBicepDeploymentParameterFileName)"
    Remove-Item -Path $tempBicepDeploymentParameterFileName
}

# Goodbye!
Write-Host "Done"