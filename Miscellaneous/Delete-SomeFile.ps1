param(
    # Path of the directory
    [Parameter(Mandatory = $true)]
    [string]
    $Directory,
    # File jump number
    [Parameter(Mandatory = $true)]
    [int]
    $FileJump,
    # Directory jump number
    [Parameter(Mandatory = $true)]
    [int]
    $DirJump
)
$filesNDirs = Get-ChildItem -Path $Directory -Recurse | Select-Object FullName, PSIsContainer
$files = $filesNDirs | Where-Object {$_.PSIsContainer -eq $false} | Select-Object -ExpandProperty FullName
$dirs = $filesNDirs | Where-Object {$_.PSIsContainer -eq $true} | Select-Object -ExpandProperty FullName | Sort-Object -Descending

$filesNDirs = $null

$i = 0
foreach ($file in $files) {
    if (($i % $FileJump) -eq 0) {
        Remove-Item $file -Force
    }
    $i++
}

$i = 0
foreach ($dir in $dirs) {
    if (($i % $DirJump) -eq 0) {
        Remove-Item $dir -Recurse -Force
    }
}