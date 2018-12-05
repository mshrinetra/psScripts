#requires -version 2
<#
.SYNOPSIS
    Get the list of shares that should be scanned
.DESCRIPTION
    This script exports the list of paths that should be scanned for various share data validation and reporting tasks
.INPUTS
    Path of Input CSV File
.OUTPUTS
    Result CSV file at working directory
.NOTES
    Version: 1.0
    Author: Manvendra Shrinetra
.LINK
    https://github.com/mshrinetra/psScripts
#>

$InputFile = Read-Host "Enter path of Input CSV file"


if (Test-Path $InputFile) {
    $csv = Import-Csv $InputFile
    $result = @()
    $resultFile = "ShareToScanResult.csv"
    $i = 0
    $c = $csv | Measure-Object | Select-Object -ExpandProperty Count
    foreach ($line in $csv) {
        $i++
        Write-Host "Checking $i of $c : $($line.FilerPath) ..."
        
        $netResponse = $null
        $shares = $null
        $netResponse = net view $line.FilerPath /all | Select-Object -Skip 7
        if ($netResponse) {
            $shares = $netResponse | Select-Object -First $(($netResponse | Measure-Object | Select-Object -ExpandProperty Count) - 2) | ForEach-Object -Process {[regex]::replace($_.trim(), '\s\s+', "`t")} | ConvertFrom-Csv -delimiter "`t" -Header 'Sharename', 'Type', 'UsedasAndComment' | Select-Object -ExpandProperty Sharename
        }
        # $shares = Get-WmiObject -Class Win32_Share -ComputerName $(($line.FilerPath) -replace [regex]::Escape("\"), "") | Select-Object -ExpandProperty Name

        foreach ($rootShare in $shares) {
            $rootSharePath = $line.FilerPath + "\" + $rootShare
            $subShares = $null
            try {
                $subShares = Get-ChildItem -LiteralPath $rootSharePath -Directory -Force -ErrorAction Stop | Select-Object -ExpandProperty FullName

                if ($subShares) {
                    foreach ($subShare in $subShares) {
                        $resultLine = New-Object psobject
                        $resultLine | Add-Member NoteProperty "Site" $line.Site
                        $resultLine | Add-Member NoteProperty "Filer" $line.Filer
                        $resultLine | Add-Member NoteProperty "Root Share" $rootShare
                        $resultLine | Add-Member NoteProperty "Root Share Path" $rootSharePath
                        $resultLine | Add-Member NoteProperty "Sub Share Path" $subShare
                        $result += $resultLine
                    }
                }
                else {
                    $resultLine = New-Object psobject
                    $resultLine | Add-Member NoteProperty "Site" $line.Site
                    $resultLine | Add-Member NoteProperty "Filer" $line.Filer
                    $resultLine | Add-Member NoteProperty "Root Share" $rootShare
                    $resultLine | Add-Member NoteProperty "Root Share Path" $rootSharePath
                    $resultLine | Add-Member NoteProperty "Sub Share Path" $rootSharePath
                    $result += $resultLine
                }
            }
            catch {
                $resultLine = New-Object psobject
                $resultLine | Add-Member NoteProperty "Site" $line.Site
                $resultLine | Add-Member NoteProperty "Filer" $line.Filer
                $resultLine | Add-Member NoteProperty "Root Share" $rootShare
                $resultLine | Add-Member NoteProperty "Root Share Path" "NOT FOUND"
                $resultLine | Add-Member NoteProperty "Sub Share Path" "--"
                $result += $resultLine
            }
        }
    }
    $r = 1
    while (Test-Path $resultFile) {
        $r++
        $resultFile = "ShareToScanResult_" + $r + ".csv"
    }
    try {
        $result | Export-Csv -Path $resultFile -Encoding Unicode -NoTypeInformation -ErrorAction Stop
        Write-Host "Scanning completed. RESULT FILE: $resultFile" -BackgroundColor Green
    }
    catch {
        Write-Host "Error in exporting the result!!" -BackgroundColor Red
        Write-Host "RESUTL: "
        $result
    }
}
else {
    Write-Host "Input file NOT FOUND! ABORTED!!" -BackgroundColor Red
}
Read-Host "Press enter to exit..."