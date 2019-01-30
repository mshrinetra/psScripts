$dir = Read-Host "Enter the directory path"

if (Test-Path $dir) {
    $csvs = Get-ChildItem -LiteralPath $dir -Force | Where-Object {($_.PSISContainer -eq $false) -and ($_.Name -like "*.csv")} | Select-Object Name, FullName

    $fileTypes = @()
    foreach ($csv in $csvs) {
        $obj = $null
        $obj = Import-Csv -LiteralPath $csv.FullName
        $headers = @($obj | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty Name | Sort-Object)
        $fileTypes += , $headers
    }

    $fileTypes = $fileTypes | Get-Unique
    foreach ($fileType in $fileTypes) {
        $outFileName = ""
        $combined = @()
        $firstFile = $true
        foreach ($csv in $csvs) {
            $obj = $null
            $obj = Import-Csv -LiteralPath $csv.FullName
            if ((Compare-Object -ReferenceObject $fileType -DifferenceObject ($obj | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name' | Sort-Object)).Length -eq 0) {
                if ($firstFile) {
                    $outFileName = $dir + "\Combined_" + $csv.Name
                    $firstFile = $false
                }
                $combined += $obj
            }
        }
        $combined | Export-Csv -LiteralPath $outFileName -Encoding Unicode -NoTypeInformation
    }
}
else {
    Write-Host "Directory not found" -BackgroundColor Red
}