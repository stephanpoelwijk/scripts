Param
(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject,
    [Parameter()]
    [string]$fileName,
    [Parameter()]
    [int]$depth = 10
)

Process {

    if ($fileName.length -gt 0) {
        $InputObject = Get-Content -Path $fileName -Raw
    }

    $InputObject | ConvertFrom-Json -Depth $depth | ConvertTo-Json -Depth $depth
}
