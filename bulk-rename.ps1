param (
    [Parameter(Mandatory = $True)]
    [string] $folder,

    [Parameter(Mandatory = $True)]
    [string] $sourceRegex,

    [Parameter(Mandatory = $True)]
    [string] $targetRegex,
    
    [Parameter()]
    [switch] $force = $False
)

$files = Get-ChildItem -Path $folder

foreach ($file in $files) {

    if ($file.Name -imatch $sourceRegex) {
        $targetFileName = $targetRegex

        for ($i = 1; $i -le $Matches.Count; $i++) {
            $Matches[$i]
            $targetFileName = $targetFileName.Replace("#$($i)", $Matches[$i]) 
        }

        if ($force) {
            "Renaming $($file.FullName) to $($targetFileName)"
            Rename-Item -Path $file.FullName -NewName $targetFileName
        }
        else {
            "Fake renaming $($file.FullName) to $($targetFileName)"
        }
    }
    else {
        "Skipping $($file.Name)"
    }
}
