[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)] [string] $name,
    [Parameter()] [string] $templateName = "webapi"
)

$solutionName = "$($name)"
$projectName = "$($name).WebApi"
$unitTestProjectName = "$($projectName).Tests"
$integrationTestProjectName = "$($projectName).Integration.Tests"

$solutionFileName = "$($name).sln"

$srcFolder = "./src"
$srcProjectFolder = "$($srcFolder)/$($projectName)"

$testsFolder = "./tests"
$unitTestProjectFolder = "$($testsFolder)/$($unitTestProjectName)"
$integrationTestProjectFolder = "$($testsFolder)/$($integrationTestProjectName)"

$generateWebApi = $templateName -eq "webapi"
$additionalGenerationParameters = ""
$generateIntegrationTestProject = $False;

if ($generateWebApi) {
    $additionalGenerationParameters += "--use-minimal-apis"
    $generateIntegrationTestProject = $True
}

"Creating solution $($name)"

New-Item -ItemType Directory -Path "$($srcFolder)"
New-Item -ItemType Directory -Path "$($testsFolder)"

# Set up the structure
dotnet new sln -n "$($solutionName)"
dotnet new $($templateName) -n "$($projectName)" -o "$($srcProjectFolder)" $additionalGenerationParameters
dotnet new xunit -n "$($unitTestProjectName)" -o "$($unitTestProjectFolder)"
if ($generateIntegrationTestProject) {
    dotnet new xunit -n "$($integrationTestProjectName)" -o "$($integrationTestProjectFolder)"
}

dotnet sln "$($solutionFileName)" add "$($srcProjectFolder)"
dotnet sln "$($solutionFileName)" add "$($unitTestProjectFolder)"

if ($generateIntegrationTestProject) {
    dotnet sln "$($solutionFileName)" add "$($integrationTestProjectFolder)"
}

# Add some package reference
dotnet add "$($unitTestProjectFolder)/$($unitTestProjectName).csproj" package FluentAssertions
dotnet add "$($unitTestProjectFolder)/$($unitTestProjectName).csproj" package NSubstitute

if ($generateIntegrationTestProject) {
    dotnet add "$($integrationTestProjectFolder)/$($integrationTestProjectName).csproj" package FluentAssertions 
    dotnet add "$($integrationTestProjectFolder)/$($integrationTestProjectName).csproj" package NSubstitute
}

# Hook up the project references
dotnet add "$($unitTestProjectFolder)/$($unitTestProjectName).csproj" reference "$($srcProjectFolder)/$($projectName).csproj"

if ($generateIntegrationTestProject) {
    dotnet add "$($integrationTestProjectFolder)/$($integrationTestProjectName).csproj" reference "$($srcProjectFolder)/$($projectName).csproj"
}

# Misc stuff
dotnet new gitignore

"Done"
