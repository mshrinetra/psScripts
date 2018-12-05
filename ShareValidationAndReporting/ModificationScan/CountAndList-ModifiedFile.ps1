#requires -version 2
<#
.SYNOPSIS
    Count modified file and calculate percentage for given number of days
.DESCRIPTION
    This script scans through the given share and directory paths to count number and calculates percentage by number and by size of the files that got modified in given number of days
.INPUTS
    Text file containing paths of shares or directories
.OUTPUTS
    CSV file with count and percentage for each path, optionally one modified file's full path
.NOTES
    Version: 1.0
    Author: Manvendra Shrinetra
.LINK
    https://github.com/mshrinetra/psScripts
#>

# ----------FUNCTIONS---------------
function Get-CountStatsFromRobocopySummary {
    [cmdletbinding()]
    param(
        # Result from Scanning application
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowEmptyString()]
        [String[]]
        $ScanSummary
    )

    BEGIN {
        $Summary = @()
    }
    PROCESS {
        $Summary += $ScanSummary
    }
    END {
        if ($Summary) {
            $allFilesCount = -1
            $modifiedFilesCount = -1
            $allFilesSize = "-0 B"
            $allFilesSizeAbsolute = 0
            $modifiedFilesSize = "-0 B"
            $modifiedFilesSizeAbsolute = 0


            $Files = $Summary | Select-Object -Index 6
            $Size = $Summary | Select-Object -Index 7

            $fileParts = $Files -split " "
            foreach ($filePart in $fileParts) {
                if ($filePart -match "^\d+$") {
                    if ($allFilesCount -eq -1) {
                        $allFilesCount = [int]$filePart
                        continue
                    }
                    elseif ($modifiedFilesCount -eq -1) {
                        $modifiedFilesCount = [int]$filePart
                        continue
                    }
                    else {
                        break
                    }
                }
            }

            $sizeParts = $Size -split " "
            $i = -1
            $allSizeIndex = 0
            $modifiedSizeIndex = 0
            foreach ($sizePart in $sizeParts) {
                $i++
                if ($sizePart -match "^[-+]?[0-9]*\.?[0-9]+$" -and $allFilesSize -eq "-0 B") {
                    $allFilesSize = $sizePart.Trim()
                    $allFilesSizeAbsolute = [double]($sizePart.Trim())
                    $allSizeIndex = $i
                    continue
                }
                if ((!($sizePart -match "^[-+]?[0-9]*\.?[0-9]+$")) -and (($allSizeIndex + 1) -eq $i) -and ($allFilesSize -ne "-0 B")) {
                    $allFilesSize = $allFilesSize + " " + ($sizePart.Trim()).ToUpper()
                    if ((($sizePart.Trim()).ToUpper()) -eq "K") {
                        $allFilesSizeAbsolute = $allFilesSizeAbsolute * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "M") {
                        $allFilesSizeAbsolute = $allFilesSizeAbsolute * 1024 * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "G") {
                        $allFilesSizeAbsolute = $allFilesSizeAbsolute * 1024 * 1024 * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "T") {
                        $allFilesSizeAbsolute = $allFilesSizeAbsolute * 1024 * 1024 * 1024 * 1024
                    }
                    continue
                }
                if ($sizePart -match "^[-+]?[0-9]*\.?[0-9]+$" -and $modifiedFilesSize -eq "-0 B") {
                    $modifiedFilesSize = $sizePart.Trim()
                    $modifiedFilesSizeAbsolute = [double]($sizePart.Trim())
                    $modifiedSizeIndex = $i
                    continue
                }
                if ((!($sizePart -match "^[-+]?[0-9]*\.?[0-9]+$")) -and (($modifiedSizeIndex + 1) -eq $i) -and ($modifiedFilesSize -ne "-0 B")) {
                    $modifiedFilesSize = $modifiedFilesSize + " " + ($sizePart.Trim()).ToUpper()
                    if ((($sizePart.Trim()).ToUpper()) -eq "K") {
                        $modifiedFilesSizeAbsolute = $modifiedFilesSizeAbsolute * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "M") {
                        $modifiedFilesSizeAbsolute = $modifiedFilesSizeAbsolute * 1024 * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "G") {
                        $modifiedFilesSizeAbsolute = $modifiedFilesSizeAbsolute * 1024 * 1024 * 1024
                    }
                    elseif ((($sizePart.Trim()).ToUpper()) -eq "T") {
                        $modifiedFilesSizeAbsolute = $modifiedFilesSizeAbsolute * 1024 * 1024 * 1024 * 1024
                    }
                }
            }

            if ($allFilesCount -le 0) {
                $modifiedFilesCountPercent = 0
                
            }
            else {
                $modifiedFilesCountPercent = [math]::Round((($modifiedFilesCount / $allFilesCount) * 100), 2)
            }

            if ($allFilesSizeAbsolute -le 0) {
                $modifiedFilesSizePercent = 0
            }
            else {
                $modifiedFilesSizePercent = [math]::Round((($modifiedFilesSizeAbsolute / $allFilesSizeAbsolute) * 100), 2)
            }

            $res = New-Object psobject
            $res | Add-Member NoteProperty "AllFileCount" $allFilesCount
            $res | Add-Member NoteProperty "ModifiedFileCount" $modifiedFilesCount
            $res | Add-Member NoteProperty "ModifiedCountPercent" $modifiedFilesCountPercent
            $res | Add-Member NoteProperty "AllFilesSize" $allFilesSize
            $res | Add-Member NoteProperty "ModifiedFilesSize" $modifiedFilesSize
            $res | Add-Member NoteProperty "ModifiedSizePercent" $modifiedFilesSizePercent
        }
        else {
            $res = "Nothing"
        }
        $res
    }
}

function Count-ForPath {
    param (
        # PathToScan
        [Parameter(Mandatory = $true)]
        [string]
        $SharePathToScan,
        # Log File Path
        [Parameter(Mandatory = $true)]
        [string]
        $LogFilePath,
        # Fake Target Path
        [Parameter(Mandatory = $true)]
        [string]
        $FakeTargetPath,
        # Filter Period (In Days)
        [Parameter(Mandatory = $true)]
        [int]
        $FilterPeriod
    )
    
    $scanResult = $null
    $resultRecord = New-Object PSObject

    $scanResult = robocopy $SharePathToScan $FakeTargetPath /s /l /nfl /ndl /njh /fp /ts /r:0 /w:0 /MAXAGE:$FilterPeriod

    $scanResult >> $LogFilePath 
    $statsResult = $scanResult | Get-CountStatsFromRobocopySummary
    Write-Host "$statsResult"

    $resultRecord | Add-Member NoteProperty "Share Path" $SharePathToScan
    $resultRecord | Add-Member NoteProperty "Modified File Count" $statsResult.ModifiedFileCount
    $resultRecord | Add-Member NoteProperty "All File Count" $statsResult.AllFileCount
    $resultRecord | Add-Member NoteProperty "Modified Count Percent" $statsResult.ModifiedCountPercent
    $resultRecord | Add-Member NoteProperty "Modified Files Size" $statsResult.ModifiedFilesSize
    $resultRecord | Add-Member NoteProperty "All Files Size" $statsResult.AllFilesSize
    $resultRecord | Add-Member NoteProperty "Modified Size Percent" $statsResult.ModifiedSizePercent

    $resultRecord
}

function ListOne-ForPath {
    param (
        # PathToScan
        [Parameter(Mandatory = $true)]
        [string]
        $SharePathToScan,
        # Log File Path
        [Parameter(Mandatory = $true)]
        [string]
        $LogFilePath,
        # Fake Target Path
        [Parameter(Mandatory = $true)]
        [string]
        $FakeTargetPath,
        # Filter Period (In Days)
        [Parameter(Mandatory = $true)]
        [int]
        $FilterPeriod
    )
    
    if ((Get-Job | Select-Object -ExpandProperty Name) -contains "mfsj") {
        Stop-Job -Name "mfsj" | Out-Null
        Remove-Job -Name "mfsj" | Out-Null
    }
    $modifiedFile = $null
    $newFileFound = $false

    Start-Job -Name "mfsj" -ScriptBlock { 
        param($SharePathToScan, $FakeTargetPath, $FilterPeriod)
        robocopy $SharePathToScan $FakeTargetPath /e /l /ns /njs /njh /ndl /fp /ts /MAXAGE:$FilterPeriod
    } -ArgumentList $SharePathToScan, $FakeTargetPath, $FilterPeriod
    
    $mfsj = Get-Job -Name "mfsj"
    while ((($mfsj | Select-Object -ExpandProperty State) -ne "Completed") -and ($newFileFound -eq $false)) {
        if (($mfsj | Select-Object -ExpandProperty HasMoreData) -eq $true) {
            $jobRes = Receive-Job -Name "mfsj"
            if ($jobRes -like "*New File*") {
                $modifiedFile = $jobRes | ForEach-Object -Process {[regex]::replace($_.trim(), '\s\s+', "`t")} | ConvertFrom-Csv -delimiter "`t" -Header "Type", "Time", "File" | Where-Object {$_.Type -like "*New File*"} | Select-Object -First 1
                $newFileFound = $true
            }
        }
        Start-Sleep -Seconds 1
        $mfsj = Get-Job -Name "mfsj"
    }

    $mfsj = Get-Job -Name "mfsj"
    if ((($mfsj | Select-Object -ExpandProperty State) -eq "Completed") -and ($newFileFound -eq $false)) {
        if (($mfsj | Select-Object -ExpandProperty HasMoreData) -eq $true) {
            $jobRes = Receive-Job -Name "mfsj"
            if ($jobRes -like "*New File*") {
                $modifiedFile = $jobRes | ForEach-Object -Process {[regex]::replace($_.trim(), '\s\s+', "`t")} | ConvertFrom-Csv -delimiter "`t" -Header "Type", "Time", "File" | Where-Object {$_.Type -like "*New File*"} | Select-Object -First 1
                $newFileFound = $true
            }
        }
    }
    $mfsj | Stop-Job | Out-Null
    $mfsj | Remove-Job | Out-Null
    $resultRecord = New-Object PSObject
    $resultRecord | Add-Member NoteProperty "Share Path" $SharePathToScan
    if ($newFileFound) {
        $resultRecord | Add-Member NoteProperty "Has Modified File" "Yes"
        $resultRecord | Add-Member NoteProperty "One modified File Path" $modifiedFile.File
        $resultRecord | Add-Member NoteProperty "Time of Last Modification" $modifiedFile.Time
    }
    else {
        $resultRecord | Add-Member NoteProperty "Has Modified File" "No"
        $resultRecord | Add-Member NoteProperty "One modified File Path" "NA"
        $resultRecord | Add-Member NoteProperty "Time of Last Modification" "NA"
    }
    $resultRecord
}

# -------------PROCESS---------------
$InputFile = (Read-Host "Enter the path of Input Text file").Trim()

$proceed = $true
$pathsToScan = $null
$fakeTarget = "CMFFakeTarget"
$countReportFile = "ModifiedCountReport.csv"
$listOneReportFile = "OneModifiedFileReport.csv"
$logFile = "CountAndListLog.log"
$scanPeriod = 90
$processChoise = 0
$startIndex = 0

if (!((Test-Path $InputFile) -and (!(Get-Item $InputFile | Select-Object -ExpandProperty PSIsContainer)))) {
    Write-Host "ERROR: Input file not Found" -ForegroundColor Red
    $proceed = $false
}
else {
    try {
        $inputRecords = Get-Content $InputFile -ErrorAction Stop
        
        Write-Host "Please answer 'g' to scan given paths"
        Write-Host "              's' to scan subdirectories of given path"
        $scanChoice = Read-Host "Your answer"

        if ($scanChoice -eq "g") {
            $pathsToScan = $inputRecords
        }
        elseif ($scanChoice -eq "s") {
            foreach ($inputRecord in $inputRecords) {
                try {
                    $pathsToScan += Get-ChildItem $inputRecord -Force -ErrorAction Stop | Where-Object {$_.PSIsContainer -eq $true} | Select-Object -ExpandProperty FullName
                }
                catch {
                    Write-Host "Error in retriving childitems of $inputRecord" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "Wrong Choice!!!" -ForegroundColor Red
            $proceed = $false
        }
    }
    catch {
        Write-Host "Error in retriving content of input file" -ForegroundColor Red
        $proceed = $false
    }
}

if ($proceed) {
    try {
        $scanPeriod = $([int]((Read-Host "Enter the number of days to scan for").Trim()))
        if ($scanPeriod -lt 1) {
            Write-Host "Wrong input. Default 90 days will take effect"
            $scanPeriod = 90
        }
    }
    catch {
        Write-Host "Wrong input. Default 90 days will take effect"
        $scanPeriod = 90
    }
}

if ($proceed) {
    if (!((Test-Path $fakeTarget) -and (Get-Item $fakeTarget | Select-Object -ExpandProperty PSIsContainer))) {
        try {
            New-Item -Path $fakeTarget -ItemType Directory -ErrorAction Stop
        }
        catch {
            Write-Host "ERROR: Failed to create Fake Target directory in current folder" -ForegroundColor Red
            $proceed = $false
        }
    }

    $i = 1
    while ((Test-Path $countReportFile) -or (Test-Path $listOneReportFile) -or (Test-Path $logFile)) {
        $i++
        $countReportFile = "ModifiedCountReport_" + $i + ".csv"
        $listOneReportFile = "OneModifiedFileReport_" + $i + ".csv"
        $logFile = "CountAndListLog_" + $i + ".log"
    }
}

if ($proceed) {
    Write-Host "Please select processes"
    Write-Host "1. Count only"
    Write-Host "2. List one file only"
    Write-Host "3. Count and List one file"
    try {
        $processChoise = $([int]((Read-Host "Enter your choise (Serial Number)").Trim()))
        if (($processChoise -lt 1) -or ($processChoise -gt 5)) {
            Write-Host "Wrong choice" -ForegroundColor Red
            $proceed = $false
        }
    }
    catch {
        Write-Host "Wrong choice" -ForegroundColor Red
        $proceed = $false
    }
}

if ($proceed) {
    Write-Host "If you are restarting the process, you can give an index to start from rather than from the begining. Give 0 to start from begining."
    try {
        $startIndex = $([int]((Read-Host "Enter the start Index (0 based index i.e. One less than Serial No)").Trim()))
        if ($startIndex -lt 0) {
            Write-Host "Wrong input. Process will start from the begining"
            $startIndex = 0
        }
    }
    catch {
        Write-Host "Wrong input. Process will start from the begining"
        $startIndex = 0
    }
}

if ($proceed) {
    $startTime = Get-Date
    Write-Host "Scanning started at $($startTime.ToString("HH:mm:ss dd-MMM-yyyy"))" -BackgroundColor Green
    
    Write-Host "Count Report: $countReportFile" -ForegroundColor Green
    Write-Host "List one Report: $listOneReportFile" -ForegroundColor Green
    Write-Host "Log File: $logFile" -ForegroundColor Green

    $countResult = @()
    $listOneResult = @()

    $pathCount = $pathsToScan | Measure-Object | Select-Object -ExpandProperty Count
    $i = 0
    foreach ($pathToScan in $pathsToScan) {
        $i++
        if ($i -le $startIndex) {
            continue
        }
        Write-Host "Scanning for $i in $pathCount ..." -ForegroundColor Yellow
        Write-Host "`t PATH: $pathToScan"


        if ($processChoise -eq 1) {
            $countRes = $null
            $countRes = Count-ForPath -SharePathToScan $pathToScan -LogFilePath $logFile -FakeTargetPath $fakeTarget -FilterPeriod $scanPeriod
            $countResult += $countRes
            $countResult | Export-Csv $countReportFile -Encoding Unicode -NoTypeInformation
        }
        elseif ($processChoise -eq 2) {
            $listOneRes = $null
            $listOneRes = ListOne-ForPath -SharePathToScan $pathToScan -LogFilePath $logFile -FakeTargetPath $fakeTarget -FilterPeriod $scanPeriod
            $listOneResult += $listOneRes
            $listOneResult | Export-Csv $listOneReportFile -Encoding Unicode -NoTypeInformation
        }
        elseif ($processChoise -eq 3) {
            $countRes = $null
            $listOneRes = $null
            $countRes = Count-ForPath -SharePathToScan $pathToScan -LogFilePath $logFile -FakeTargetPath $fakeTarget -FilterPeriod $scanPeriod
            $countResult += $countRes
            $countResult | Export-Csv $countReportFile -Encoding Unicode -NoTypeInformation
            if ($countRes."Modified File Count" -lt 0) {
                $listOneRes = New-Object PSObject
                $listOneRes | Add-Member NoteProperty "Share Path" $pathToScan
                $listOneRes | Add-Member NoteProperty "Has Modified File" "Failed"
                $listOneRes | Add-Member NoteProperty "One modified File Path" "NA"
                $listOneRes | Add-Member NoteProperty "Time of Last Modification" "NA"
            }
            elseif ($countRes."Modified File Count" -eq 0) {
                $listOneRes = New-Object PSObject
                $listOneRes | Add-Member NoteProperty "Share Path" $pathToScan
                $listOneRes | Add-Member NoteProperty "Has Modified File" "No"
                $listOneRes | Add-Member NoteProperty "One modified File Path" "NA"
                $listOneRes | Add-Member NoteProperty "Time of Last Modification" "NA"
            }
            else {
                $listOneRes = ListOne-ForPath -SharePathToScan $pathToScan -LogFilePath $logFile -FakeTargetPath $fakeTarget -FilterPeriod $scanPeriod
            }
            $listOneResult += ($listOneRes | Where-Object { $_."Share Path" -ne "" } )
            $listOneResult | Where-Object {$_."Share Path" -ne ""} | Export-Csv $listOneReportFile -Encoding Unicode -NoTypeInformation
        }
    }
    Write-Host "Scanning ompleted !!!" -BackgroundColor Green
    $endTime = Get-Date
    $delay = $endTime - $startTime

    Write-Host $("=" * 72) -ForegroundColor Yellow

    Write-Host "===SUMMARY$("="*54)" -ForegroundColor Green
    Write-Host "Sart Time:       $($startTime.ToString("HH:mm:ss dd-MMM-yyyy")) " -ForegroundColor Green
    Write-Host "End Time:        $($endTime.ToString("HH:mm:ss dd-MMM-yyyy")) " -ForegroundColor Green
    Write-Host "Paths Counted:   $pathCount" -ForegroundColor Green
    Write-Host "Total Time:      $($delay.Days) Days, $($delay.Hours) Hours, $($delay.Minutes) Minutes and $($delay.Seconds).$($delay.Milliseconds) Seconds" -ForegroundColor Green
    Write-Host $("=" * 64) -ForegroundColor Green
}
