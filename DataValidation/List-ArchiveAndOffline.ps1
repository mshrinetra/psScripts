param(
    # Path of the Mapping CSV file
    [Parameter(Mandatory = $true)]
    [string]
    $InputTextFile,
    # Path of the empety report directory
    [Parameter(Mandatory = $true)]
    [string]
    $ReportDirectory
)

$InputTextFile = $InputTextFile.Trim()
$ReportDirectory = $ReportDirectory.Trim()

$proceed = $true

if (!((Test-Path $InputTextFile) -and (!(Get-Item $InputTextFile | Select-Object -ExpandProperty PSIsContainer)))) {
    Write-Host "ERROR: Input file not Found" -ForegroundColor Red
    $proceed = $false
}
else {
    $toScanPaths = Get-Content $InputTextFile
}

$currentDir = Get-Location | Select-Object -ExpandProperty Path

if ($proceed) {
    $reportDirNotOk = $false
    if ($ReportDirectory) {
        if (!((Test-Path $ReportDirectory) -and (Get-Item $ReportDirectory | Select-Object -ExpandProperty PSIsContainer))) {
            Write-Host "ERROR: Report Directory not found" -ForegroundColor Red
            $reportDirNotOk = $true
        }
        else {
            if ((Get-ChildItem $ReportDirectory | Measure-Object | Select-Object -ExpandProperty Count) -ne 0) {
                Write-Host "ERROR: Report Directory not Empty" -ForegroundColor Red
                $reportDirNotOk = $true
            }
        }
    }

    if ($reportDirNotOk) {
        Write-Host "Creating Report Directory in current directory..." -ForegroundColor Blue
        $i = 1
        $ReportDirectory = $currentDir + "\" + "AOAttributeReport" + $i
        while (Test-Path $ReportDirectory) {
            $i++
            $ReportDirectory = $currentDir + "\" + "AOAttributeReport" + $i
        }

        New-Item -Path $ReportDirectory -ItemType Directory

        if (!(Test-Path $ReportDirectory)) {
            Write-Host "ERROR: Failed to create report directory in current folder" -ForegroundColor Red
            $proceed = $false
        }
        else {
            Write-Host "New report directory: $ReportDirectory" -ForegroundColor Blue
        }
    }
}

if ($proceed) {
    $fakeTargetDirectory = $ReportDirectory + "\EmptyTarget"
    New-Item -Path $fakeTargetDirectory -ItemType Directory
    if (!(Test-Path $fakeTargetDirectory)) {
        Write-Host "ERROR: Failed to create fake target directory in report directory" -ForegroundColor Red
        $proceed = $false
    }
    else {
        Write-Host "New fake target directory: $fakeTargetDirectory" -ForegroundColor Blue
    }
}

if ($proceed) {
    Write-Host "Please answer 'a' for archive only"
    Write-Host "              'o' for offline only"
    Write-Host "              'b' for both archive and offline"
    $scanChoice = Read-Host "Your answer"

    if ($scanChoice -eq "a") {
        Write-Host "Only archived files will be scnned." -ForegroundColor Blue
        $reportFilePrefix = "Archive"
    }
    elseif ($scanChoice -eq "o") {
        Write-Host "Only offline files will be scnned." -ForegroundColor Blue
        $reportFilePrefix = "Offline"
    }
    elseif ($scanChoice -eq "b") {
        $scanChoice = "ao"
        Write-Host "Both archived and offline files will be scnned." -ForegroundColor Blue
        $reportFilePrefix = "ArchiveOffline"
    }
    else {
        Write-Host "You entered awrong answer" -ForegroundColor Red
        $proceed = $false
    }
}

if ($proceed) {

    $computerName = $env:COMPUTERNAME

    if (Test-Path ".\config.json") {
        $doMail = $false
        $config = $null
        try {
            $config = Get-Content ".\config.json" | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Host "Unable to decode configuration" -ForegroundColor Red
        }

        if (!($config)) {
            Write-Host "Mail cannot be sent!!" -ForegroundColor Yellow
        }
        elseif ($config.DoMail -eq "Yes") {
            $doMail = $true
        }
        else {
            Write-Host "Mail Sending is Disabled!!" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No configuration for sending mail." -ForegroundColor Yellow
    }

    $index = @()
    $indexFile = $ReportDirectory + "\_Index.csv"
    $toScanPathCount = $toScanPaths | Measure-Object | Select-Object -ExpandProperty Count
    $i = 0
    
    foreach ($toScanPath in $toScanPaths) {
        $i++
        Write-Host "Scanning $i of $toScanPathCount : $toScanPath ..."
        $reportFile = $ReportDirectory + "\" + $reportFilePrefix + $i + ".txt"
        $indexItem = New-Object PSObject
        $indexItem | Add-Member NoteProperty "Path" $toScanPath
        $indexItem | Add-Member NoteProperty "ReportFile" $reportFile

        if ($doMail) {
            $reportZipFile = $ReportDirectory + "\" + $reportFilePrefix + "_zip_" + $i + ".zip"
            $indexItem | Add-Member NoteProperty "ReportZipFile" $reportZipFile
        }
        
        $index += $indexItem
        $index | Export-Csv $indexFile -NoTypeInformation -Encoding Unicode

        robocopy $toScanPath $fakeTargetDirectory /e /l /ns /njs /njh /ndl /fp /ia:$scanChoice /log:$reportFile
        
        if ($doMail) {
            
            Compress-Archive -LiteralPath $reportFile -CompressionLevel Optimal -DestinationPath $reportZipFile
    
            if (Test-Path $reportZipFile) {
                Write-Host "Report Zip File: $reportZipFile" -ForegroundColor Green

                $body = "<div>Hello,<br><b>File Scan Status:</b><br>At server $computerName, scanning $i of $toScanPathCount Copleted. <br> For path: $toScanPath <br> Attached is the report. <br><br><small>This is a system generated mail. Please do not Respond.</small></div>"
                
                try {
                    Send-MailMessage -To $config.To -Cc $config.Cc -From $config.From -Subject "File Scan Report" -Body $body -BodyAsHtml -Attachments $reportZipFile -SmtpServer $config.SMTPServer -Port $config.Port -ErrorAction Stop
                    Write-Host "Report Mail Sent!" -ForegroundColor Green
                }
                catch {
                    Write-Host "Report Mail Failed!!!" -ForegroundColor Red
                }
                
            }
            else {
                Write-Host "Faild to zip reports!" -ForegroundColor Yellow
                $body = "<div>Hello,<br><b>File Scan Status:</b><br>At server $computerName, scanning $i of $toScanPathCount Copleted. <br> For path: $toScanPath <br> Report could not be zipped. <br><br><small>This is a system generated mail. Please do not Respond.</small></div>"
                try {
                    Send-MailMessage -To $config.To -Cc $config.Cc -From $config.From -Subject "Validation Status" -Body $body -BodyAsHtml -SmtpServer $config.SMTPServer -Port $config.Port -ErrorAction Stop
                    Write-Host "Status Mail Sent!" -ForegroundColor Green
                }
                catch {
                    Write-Host "Status Mail Failed!!!" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host "Scanning Completed!!!" -ForegroundColor Green

    Read-Host "Press Enter to Exit"
}
else {
    Write-Host "ABORTED!!!" -BackgroundColor Red
}