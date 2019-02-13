param(
    # Directory in which Subtitle files have to be prepended with Z_
    [Parameter(Mandatory)]
    [string]
    $DirectoryPath,
    # File extension of Subtitle files
    [Parameter(Mandatory)]
    [string]
    $FileExtension
)

$files = Get-ChildItem -LiteralPath $DirectoryPath -Recurse | Where-Object {$_.Name -like "*.$FileExtension"}
foreach ($file in $files) {
    Rename-Item -LiteralPath ($file.FullName) -NewName ("Z_" + ($file.Name)) -Force
    Write-Host "$($file.Name) RENAMED TO $("Z_" + ($file.Name))"
}