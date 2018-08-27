param(
    # Path of the Mapping CSV file
    [Parameter(Mandatory = $true)]
    [string]
    $MappingFile,
    # Path of the empety report directory
    [Parameter(Mandatory = $true)]
    [string]
    $ReportDirectory
)

$MappingFile = $MappingFile.Trim()
$ReportDirectory = $ReportDirectory.Trim()

$proceed = $true

if (!((Test-Path $MappingFile) -and (!(Get-Item $MappingFile | Select-Object -ExpandProperty PSIsContainer)))) {
    Write-Host "ERROR: Mapping file not Found" -ForegroundColor Red
    $proceed = $false
}
else {
    $mapping = Import-Csv $MappingFile
    $headers = $mapping | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
    if (!(($headers -contains "Source") -and ($headers -contains "Destination"))) {
        Write-Host "ERROR: Mapping file format Incorrect" -ForegroundColor Red
        $proceed = $false
    }
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
        $ReportDirectory = $currentDir + "\" + "ValidationReports" + $i
        while (Test-Path $ReportDirectory) {
            $i++
            $ReportDirectory = $currentDir + "\" + "ValidationReports" + $i
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
    $mapCount = $mapping | Measure-Object | Select-Object -ExpandProperty Count
    $i = 0
    
    foreach ($map in $mapping) {
        $i++
        Write-Host "Validating $i of $mapCount"
        $reportFile = $ReportDirectory + "\Diffs" + $i + ".txt"
        $indexItem = New-Object PSObject
        $indexItem | Add-Member NoteProperty "Source" $map.Source
        $indexItem | Add-Member NoteProperty "Destination" $map.Destination
        $indexItem | Add-Member NoteProperty "DiffReportFile" $reportFile
        $index += $indexItem
        $index | Export-Csv $indexFile -NoTypeInformation -Encoding Unicode

        robocopy $map.Source $map.Destination /e /l /ns /njs /njh /ndl /fp /log:$reportFile

        if ($doMail) {
            $body = "<div>Hello,<br><b>Validation Status:</b><br>At server $computerName, validation $i of $mapCount Copleted. <br> For Source: $($map.Source) <br> And Destination: $($map.Destination) <br><br><small>This is a system generated mail. Please do not Respond.</small></div>"
            try {
                Send-MailMessage -To $config.To -Cc $config.Cc -From $config.From -Subject "Validation Status" -Body $body -BodyAsHtml -Attachments $reportZipFile -SmtpServer $config.SMTPServer -Port $config.Port -ErrorAction Stop
                Write-Host "Status Mail Sent!" -ForegroundColor Green
            }
            catch {
                Write-Host "Status Mail Failed!!!" -ForegroundColor Red
            }
        }
    }

    $reportZipFile = $currentDir + "\" + "ValidationReports" + ((Get-Date).ToString("ddMMyyyyHHmmss")) + ".zip"
    
    Write-Host "Validation Completed!!!" -ForegroundColor Green
    
    Compress-Archive -LiteralPath $ReportDirectory -CompressionLevel Optimal -DestinationPath $reportZipFile
    
    if (Test-Path $reportZipFile) {
        Write-Host "Report Zip File: $reportZipFile" -ForegroundColor Green

        if ($doMail) {
            $body = "<div>Hello,<br>PFA Validation Report from $computerName.<br><br><small>This is a system generated mail. Please do not Respond.</small></div>"
            try {
                Send-MailMessage -To $config.To -Cc $config.Cc -From $config.From -Subject "Validation Report" -Body $body -BodyAsHtml -Attachments $reportZipFile -SmtpServer $config.SMTPServer -Port $config.Port -ErrorAction Stop
                Write-Host "Report Mail Sent!" -ForegroundColor Green
            }
            catch {
                Write-Host "Report Mail Failed!!!" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "Faild to zip reports!" -ForegroundColor Yellow
    }

    Read-Host "Press Enter to Exit"
}
else {
    Write-Host "ABORTED!!!" -BackgroundColor Red
}