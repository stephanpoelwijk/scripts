param (
    [Parameter(Mandatory = $True)] [string] $scriptFileName,
    [Parameter()] [switch] $includeCommonParameters = $False,
    [Parameter()] [switch] $usePowerShellCore = $False,
    [Parameter()] [switch] $force = $False
)
Import-Module powershell-yaml

$parameters = (get-command -name $scriptFileName ).Parameters

$yamlObject = [ordered] @{
    "parameters" = @();
    "steps"      = @();
}

# Fill up the parameter list
foreach ($parameterName in ($parameters.Keys | Sort-Object)) { 

    if (!$includeCommonParameters -and [System.Management.Automation.Cmdlet]::CommonParameters.Contains($parameterName)) {
        continue
    }

    $parameterType = 'string'
    if ($parameters[$parameterName].SwitchParameter) {
        $parameterType = "boolean"
    }
    elseif ($parameters[$parameterName].ParameterType.Name -eq 'Int32') {
        $parameterType = "number"
    }

    $yamlObject['parameters'] += @{ 'name' = $parameterName; 'type' = $parameterType }
}

# Fill up the steps
$step = [ordered] @{
    "task"   = "PowerShell@2";
    "inputs" = [ordered]@{
        "targetType" = "filePath";
        "filePath"   = $scriptFileName;
    };
};

if ($usePowerShellCore) {
    $step['inputs']['pwsh'] = $true
}

$yamlObject['steps'] += $step

# Write things out
$yamlObject | ConvertTo-Yaml