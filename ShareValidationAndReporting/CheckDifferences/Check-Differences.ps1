<#
.SYNOPSIS
Check the difference between files at two locations
.DESCRIPTION
Thsis script checks the difeerence between files at two locations recursively and exports the list of files and folders that do not exists at either of the locations or have any differences. It uses the robocopy for fast and robust scanning.
.INPUTS
Path of Input CSV File, that contains source and destination paths under columns titled "Source" and "Destination". Also path of report directory where results need to be saved.
.OUTPUTS
One index (CSV) file containing the path of report for each path and report files itself in a subdirectory named Validation report in report directory
.EXAMPLE
PS C:\> .\Validate-Differences.ps1
Please enter the path of Input map file: map.csv
Enter the path of directory where the result will be saved: .
Creating new subdirectory in report directory to keep all the reports


    Directory: C:\


Mode                LastWriteTime     Length Name
----                -------------     ------ ----
d----         3/13/2019   4:42 PM            ValidationReports_2
Reports for this scan will be saved in: .\ValidationReports_2
Validation started at 16:42:28 13-Mar-2019
========================================================================
------------------------------------------------------------------------
Validating 1 of 1 for
SOURCE: C:\Users\testuser\Desktop\Source
DESTINATION: C:\Users\testuser\Desktop\Destination

 Log File : C:\ValidationReports_2\Diffs1.txt
------------------------------------------------------------------------
========================================================================
Validation Completed!!!
===SUMMARY======================================================
Sart Time:       16:42:28 13-Mar-2019
End Time:        16:42:28 13-Mar-2019
Paths Validated: 1
Total Time:      0 Days, 0 Hours, 0 Minutes and 0.251 Seconds
================================================================


.NOTES
Version: 1.0
Author: Manvendra Shrinetra
.LINK
https://github.com/mshrinetra/psScripts
#>
#requires -version 2

$InputMapFile = Read-Host "Please enter the path of Input map file"
$ReportDirectory = Read-Host "Enter the path of directory where the result will be saved"

$InputMapFile = $InputMapFile.Trim()
$ReportDirectory = $ReportDirectory.Trim()

$proceed = $true
$mapping = $null

if (!((Test-Path $InputMapFile) -and (!(Get-Item $InputMapFile | Select-Object -ExpandProperty PSIsContainer)))) {
    Write-Host "ERROR: Mapping file not Found" -ForegroundColor Red
    $proceed = $false
}
else {
    $mapping = Import-Csv $InputMapFile
    $headers = $mapping | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
    if (!(($headers -contains "Source") -and ($headers -contains "Destination"))) {
        Write-Host "ERROR: Mapping file format Incorrect" -ForegroundColor Red
        $proceed = $false
    }
}


if ($proceed) {
    if (!((Test-Path $ReportDirectory) -and (Get-Item $ReportDirectory | Select-Object -ExpandProperty PSIsContainer))) {
        $currentDir = Get-Location | Select-Object -ExpandProperty Path
        Write-Host "ERROR: Report Directory not found" -ForegroundColor Red
        Write-Host "Report(s) will be saved in current working directory i.e. $currentDir" -ForegroundColor Yellow
        $ReportDirectory = "."
    }

    Write-Host "Creating new subdirectory in report directory to keep all the reports"
    $ReportSubDirectory = $ReportDirectory + "\ValidationReports"
    while (Test-Path $ReportSubDirectory) {
        $i++
        $ReportSubDirectory = $ReportDirectory + "\ValidationReports_" + $i
    }

    try {
        New-Item -Path $ReportSubDirectory -ItemType Directory -ErrorAction Stop
        Write-Host "Reports for this scan will be saved in: $ReportSubDirectory" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to create report subdirectory in report directory" -ForegroundColor Red
        $proceed = $false
    }
}

if ($proceed) {
    $startTime = Get-Date
    Write-Host "Validation started at $($startTime.ToString("HH:mm:ss dd-MMM-yyyy"))"
    Write-Host $("=" * 72) -ForegroundColor Yellow

    $index = @()
    $indexFile = $ReportSubDirectory + "\_Index.csv"
    $mapCount = $mapping | Measure-Object | Select-Object -ExpandProperty Count
    $i = 0
    
    foreach ($map in $mapping) {
        Write-Host $("-" * 72) -ForegroundColor Blue
        $i++
        Write-Host "Validating $i of $mapCount for"
        Write-Host "SOURCE: $($map.Source)"
        Write-Host "DESTINATION: $($map.Destination)"
        $reportFileName = "Diffs" + $i + ".txt"
        $reportFile = $ReportSubDirectory + "\" + $reportFileName
        $indexItem = New-Object PSObject
        $indexItem | Add-Member NoteProperty "Source" $map.Source
        $indexItem | Add-Member NoteProperty "Destination" $map.Destination
        $indexItem | Add-Member NoteProperty "DiffReportFile" $reportFileName
        $index += $indexItem
        try {
            $index | Export-Csv $indexFile -NoTypeInformation -Encoding Unicode -Force -ErrorAction Stop
        }
        catch {
            Write-Host "WARNING: Failed to update index file" -ForegroundColor Yellow
        }

        robocopy $map.Source $map.Destination /e /l /ns /njs /njh /ndl /fp /log:$reportFile

        Write-Host $("-" * 72) -ForegroundColor Green
    }
    
    
    $endTime = Get-Date
    $delay = $endTime - $startTime
    Write-Host $("=" * 72) -ForegroundColor Yellow
    Write-Host "Validation Completed!!!" -ForegroundColor Green

    Write-Host "===SUMMARY$("="*54)" -ForegroundColor Green
    Write-Host "Sart Time:       $($startTime.ToString("HH:mm:ss dd-MMM-yyyy")) " -ForegroundColor Green
    Write-Host "End Time:        $($endTime.ToString("HH:mm:ss dd-MMM-yyyy")) " -ForegroundColor Green
    Write-Host "Paths Validated: $mapCount" -ForegroundColor Green
    Write-Host "Total Time:      $($delay.Days) Days, $($delay.Hours) Hours, $($delay.Minutes) Minutes and $($delay.Seconds).$($delay.Milliseconds) Seconds" -ForegroundColor Green
    Write-Host $("=" * 64) -ForegroundColor Green
}
else {
    Write-Host "ABORTED!!!" -BackgroundColor Red
}

Start-Sleep -Seconds 10