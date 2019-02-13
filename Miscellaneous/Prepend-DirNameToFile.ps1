$folder = Read-Host "Enter the path of folder"
$ext = Read-Host "Enter the extention of files"
if (Test-Path $folder) {
    $dirs = Get-ChildItem $folder | Where-Object {($_.PsIsContainer -eq $true) -and ($_.Name -ne "_PrependedFiles")}
    New-Item $($folder + "\_PrependedFiles") -ItemType Directory -Force
    foreach ($dir in $dirs) {
        $files = $null
        $files = Get-ChildItem $dir.FullName | Where-Object { ($_.PsIsContainer -eq $false) -and ($_.Name -like "*$ext")}
        foreach ($file in $files) {
            try {
                Write-Host "FROM: $($file.FullName)"
                Write-Host "TO  : $($folder + "\_PrependedFiles\" + $dir.Name + "_" + $file.Name)"
                Copy-Item $file.FullName -Destination $($folder + "\_PrependedFiles\" + $dir.Name + "_" + $file.Name) -Force -ErrorAction Stop
                Write-Host "Success!" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed!!!" -ForegroundColor Red
            }
        }
    }
}