param (
    [Parameter(Mandatory = $True)]
    [string] $folder,

    [Parameter()]
    [switch] $force = $False
)


$files = Get-ChildItem -Path $folder

foreach ($file in $files) {
    $targetFileName = "$($folder)\$($file.Name.replace("_", "\"))" 

    "Moving $($file.FullName) to $($targetFileName)"

    if ($force) {
        $targetFolder = [System.IO.Path]::GetDirectoryName($targetFileName)
        if (!(Test-Path -Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory
        }
    
        Move-Item -Path $file.FullName -Destination $targetFileName
    }
}