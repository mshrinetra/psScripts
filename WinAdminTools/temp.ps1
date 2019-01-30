$file = Read-Host "File"
$paths = Get-Content $file
$result = @()
$i = 0
foreach ($path in $paths) {
    $i++
    $res = ""
    $line = New-Object psobject
    $line | Add-Member NoteProperty "Sno" [string]$i
    $line | Add-Member NoteProperty "DFS Path" $path
    $line | Add-Member NoteProperty "Physical Path" $res
    $result += $line
}
$result | Export-Csv "PhysicalPaths.csv" -Encoding Unicode -NoTypeInformation