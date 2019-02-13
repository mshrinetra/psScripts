$csvFile = Read-Host "Enter path of csv file"
if (Test-Path $csvFile) {
    $csv = Import-Csv $csvFile
    $splitOn = Read-Host "Enter the header to split on"
    $property = Read-Host "Enter the property to split"
    $createFolder = Read-Host "Create folder too? (Y/N)"
    if ($createFolder -eq "y") {
        $commanName = "Give comman name to files in each folder(Give N for No, or give the common name)"
    }
    $headers = $csv | Select-Object -ExpandProperty $splitOn | Get-Unique
    foreach ($header in $headers) {
        $text = $null
        $text = $csv | Where-Object {$_.($splitOn) -eq $header} | Select-Object -ExpandProperty $property
        if ($createFolder -eq "y") {
            New-Item -Name $header -ItemType Directory -Force
            if ($commanName -ne "n") {
                $text | Out-File $(".\" + $header + "\" + $commanName + ".txt") -Encoding Unicode
            }
            else {
                $text | Out-File $(".\" + $header + "\" + $header + ".txt") -Encoding Unicode
            }
        }
        else {
            $text | Out-File $($header + ".txt") -Encoding Unicode
        }
    }
}