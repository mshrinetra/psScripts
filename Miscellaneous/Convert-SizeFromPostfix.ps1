$inputFilePath = (Read-Host "Enter CSV file path").Trim()
if (Test-Path $inputFilePath) {

    $inputfile = Import-Csv $inputFilePath
    $header = (Read-Host "Enter header").Trim()
    $result = @()
    foreach ($line in $inputfile) {
        $text = $null
        $newText = $null
        $newLine = $null
        $rawSize = 0
        $mult = 1
        $text = $line | Select-Object -ExpandProperty $header
        if ($text -like "-*") {
            $mult = 0
            $newText = 0
        }
        elseif ($text -like "*b*") {
            $mult = 1
            $newText = ($text -replace "B", "").Trim()
        }
        elseif ($text -like "*k*") {
            $mult = 1024
            $newText = ($text -replace "K", "").Trim()
        }
        elseif ($text -like "*m*") {
            $mult = (1024 * 1024)
            $newText = ($text -replace "M", "").Trim()
        }
        elseif ($text -like "*g*") {
            $mult = (1024 * 1024 * 1024)
            $newText = ($text -replace "G", "").Trim()
        }
        elseif ($text -like "*t*") {
            $mult = (1024 * 1024 * 1024 * 1024)
            $newText = ($text -replace "T", "").Trim()
        }
        else {
            $mult = 1
            $newText = $text.Trim()
        }
        
        $rawSize = [double]::Parse($newText) * $mult
        $newLine = $line | Select-Object *, @{N = "InByte"; E = {$rawSize}}
        $result += $newLine
    }
    $opFilePath = (Read-Host "Enter output file path").Trim()
    $result | Export-Csv $opFilePath -Encoding Unicode -NoTypeInformation
}
else {
    Write-Host "Invalid file" -BackgroundColor Red
}