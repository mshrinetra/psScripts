<#
.SYNOPSIS
Compare network device configuration with template

.DESCRIPTION
This script is to compare the configuration files, extracted from network devices with the standard template.

.INPUTS
Path of the directory containing "template.txt", "master.csv" and configuration files

.OUTPUTS
Report CSV files

.EXAMPLE
PS C:\Users\mshri\SandBox\psScripts\Network Script> .\Compare-TemplateWithConfig.ps1
Enter the path of the directory: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory
Reports will be saved in C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1

Analysing bdeman00swc00...
        Done.    Report File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1\Report_bdeman00swc00.csv

Analysing bdemanEXAMPLE...
        Done.    Report File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1\Report_bdemanEXAMPLE.csv
Press 'ENTER' to exit.:

.NOTES
Version: 1.0
Author: Manvendra Shrinetra
.LINK
https://github.com/mshrinetra/psScripts
#>


$dirPath = Read-Host "Enter the path of the directory"

$files = $null
$proceed = $true    # To check if all the prerequisits are met
$reportDirPath = $null      # To store the reports
$templatePath = $null
$masterFilePath = $null

# Check if the given directory exists
if (Test-Path -LiteralPath $dirPath -PathType Container) {
    
    # Check if template exists in the given directory
    $templatePath = Join-Path -Path $dirPath -ChildPath "template.txt"
    if (!(Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        # Print error if template does not exists
        $proceed = $false
        Write-Host "ERROR: Directory does not have 'template.txt' in it!" -ForegroundColor Red
    }

    # Check if master record CSV file exists
    $masterFilePath = Join-Path -Path $dirPath -ChildPath "master.csv"
    if (!(Test-Path -LiteralPath $masterFilePath -PathType Leaf)) {
        # Print error if master does not exists
        $proceed = $false
        Write-Host "ERROR: Directory does not have 'master.csv' in it!" -ForegroundColor Red
    }

    if ($proceed) {
        # Get all the config (hopefully) files in the directory
        $files = Get-ChildItem -LiteralPath $dirPath -File | Where-Object { $_.Name -ne "template.txt" -and $_.Name -ne "master.csv" } | Select-Object -ExpandProperty FullName

        # if there are at least one config file
        if ($files.Length -lt 1) {
            # Print error if there is no config files in the directory
            $proceed = $false
            Write-Host "ERROR: There are no config files in the given directory!" -ForegroundColor Red
        }
    }

    if ($proceed) {
        # Create a directory to store reports
        $reportDirCount = 1
        $reportDirPath = Join-Path -Path $dirPath -ChildPath $("Reports_" + $reportDirCount)
        while (Test-Path -LiteralPath $reportDirPath -PathType Container) {
            $reportDirCount = $reportDirCount + 1
            $reportDirPath = Join-Path -Path $dirPath -ChildPath $("Reports_" + $reportDirCount)
        }

        try {
            New-Item -Path $reportDirPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Reports will be saved in $($reportDirPath)" -ForegroundColor Yellow
        }
        catch {
            $proceed = $false
            Write-Host "ERROR: Failed to create report directory!" -ForegroundColor Red
        }
    }
}
else {
    # Print error if given directory does not exists
    $proceed = $false
    Write-Host "ERROR: Directory Not Found!" -ForegroundColor Red
}

# If all the prerequisits are met start comparison
if ($proceed) {
    $master = Import-Csv $masterFilePath
    $templateContent = Get-Content -LiteralPath $templatePath | Sort-Object
    $devicesInMaster = $master | Get-member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
    
    foreach ($file in $files) {
        $configContent = $null
        $result = @()
        $filename = [io.path]::GetFileNameWithoutExtension($file)
        $reportFilePath = Join-Path -Path $reportDirPath -ChildPath $("Report_" + $filename + ".csv")

        if ($devicesInMaster -contains $filename) {
            Write-Host "`nAnalysing $($filename)..." -ForegroundColor Yellow

            $configContent = Get-Content -LiteralPath $file | Sort-Object

            $comarisonResult = Compare-Object -ReferenceObject $templateContent -DifferenceObject $configContent -IncludeEqual
            $comarisonResult >> "Debug.txt"

            $equalContents = $comarisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("==") } | Select-Object -ExpandProperty InputObject
            $onlyInTemplate = $comarisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("<=") } | Select-Object -ExpandProperty InputObject
            $onlyInConfig = $comarisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("=>") } | Select-Object -ExpandProperty InputObject

            foreach ($content in $equalContents) {
                $result += "" | Select-Object @{N = "Statement in Template"; E = { $content } }, @{N = "Statement in Config"; E = { $content } }, @{N = "Is Mached?"; E = { "Yes" } }
            }

            $masterMap = @()
            foreach ($line in $master) {
                $masterMap += "" | Select-Object @{N = "Statement"; E = { $line.Statement } }, @{N = "MappedStatement"; E = {
                        $line.Statement -replace [regex]::Escape($line.Variable), $($line | Select-Object -ExpandProperty $filename)
                    }
                }
            }

            $onlyInConfigCleaned = ($onlyInConfig -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), ""
            
            foreach ($line in $onlyInTemplate) {
                $cleaned = ($line -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), ""
                
                $foundObj = $null
                $foundObj = $masterMap | Where-Object { $_.Statement -eq $line -or (($_.Statement -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), "") -eq $cleaned }
                if ($foundObj) {
                    $index = [array]::IndexOf($masterMap, $foundObj[0])
                    if ($onlyInConfigCleaned -contains $(($masterMap[$index].MappedStatement -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), "")) {
                        $onlyInConfigCleaned = $onlyInConfigCleaned | Where-Object { $_ -ne $(($masterMap[$index].MappedStatement -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), "") }
                        $result += "" | Select-Object @{N = "Statement in Template"; E = { $line } }, @{N = "Statement in Config"; E = { $masterMap[$index].MappedStatement } }, @{N = "Is Mached?"; E = { "Yes" } }
                    }
                }
                else {
                    $result += "" | Select-Object @{N = "Statement in Template"; E = { $line } }, @{N = "Statement in Config"; E = { "" } }, @{N = "Is Mached?"; E = { "No" } }
                }

            }

            foreach ($line in $onlyInConfigCleaned) {
                $result += "" | Select-Object @{N = "Statement in Template"; E = { "" } }, @{N = "Statement in Config"; E = { $line } }, @{N = "Is Mached?"; E = { "Extra" } }
            }
            
            try {
                $result | Export-Csv -LiteralPath $reportFilePath -Encoding Unicode -NoTypeInformation -ErrorAction Stop
                Write-Host "`tDone.`t Report File: $($reportFilePath)" -ForegroundColor Green
            }
            catch {
                Write-Host "\tFailed to save report!" -ForegroundColor Red
            }
        }
        else {
            Write-Host "'master.csv' does not contyains record for $($filename)!" -ForegroundColor Red
        }
    }
}
# To keep the prompet open
Read-Host "Press 'ENTER' to exit."
