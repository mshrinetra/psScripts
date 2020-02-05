<#
.SYNOPSIS
Work with network device configuration and template

.DESCRIPTION
This script is to compare the configuration files, extracted from network devices with the standard template and to create configuration file using template.

.INPUTS
Path of the directory containing "template.txt", "master.csv" and configuration files

.OUTPUTS
Report CSV files or configuration file

.EXAMPLE
PS > .\WorkWith-TemplateAndConfig.ps1
Process Chices:
        1. Validation
        2. Create config
Enter your choice: 2
Validation Process:
Enter the path of the directory: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory
Reports will be saved in C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1

Analysing bdeman00swc00...
        Done.    Report File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1\Report_bdeman00swc00.csv

Analysing bdemanEXAMPLE...
        Done.    Report File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_1\Report_bdemanEXAMPLE.csv
Press 'ENTER' to exit.:

.EXAMPLE
PS > .\WorkWith-TemplateAndConfig.ps1
Process Chices:
        1. Validation
        2. Create config
Enter your choice: 2
Config file creation process:
Enter the path of the directory: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory
Reports will be saved in C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_2
Enter the name of devices, separated by comma (Enter all for all devices): all
Creating configuration for bdeman00swc00 ...
        Done.    Config File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_2\Config_bdeman00swc00.txt
Creating configuration for bdemanEXAMPLE ...
        Done.    Config File: C:\Users\mshri\SandBox\psScripts\Network Script\Working Directory\Reports_2\Config_bdemanEXAMPLE.txt
Press 'ENTER' to exit.:

.NOTES
Version: 1.0
Author: Manvendra Shrinetra
.LINK
https://github.com/mshrinetra/psScripts
#>


Write-Host "Process Chices:"
Write-Host "`t1. Validation"
Write-Host "`t2. Create config"
$processChice = Read-Host "Enter your choice"

if ($processChice -eq "1") {
    Write-Host "Validation process:" -BackgroundColor Yellow -ForegroundColor Black
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
    
        # Iterate for each config file
        foreach ($file in $files) {
            $configContent = $null
            $result = @()
            $filename = [io.path]::GetFileNameWithoutExtension($file)
            $reportFilePath = Join-Path -Path $reportDirPath -ChildPath $("Report_" + $filename + ".csv")

            # Check if the device is in master
            if ($devicesInMaster -contains $filename) {

                # IF it exists
                Write-Host "`nAnalysing $($filename)..." -ForegroundColor Yellow

                # Read the config file
                $configContent = Get-Content -LiteralPath $file | Sort-Object

                # Compare config with template
                $comparisonResult = Compare-Object -ReferenceObject $templateContent -DifferenceObject $configContent -IncludeEqual

                # Matched content do not need to further processed, and export it to a file
                $equalContents = $comparisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("==") } | Select-Object -ExpandProperty InputObject
                $onlyInTemplate = $comparisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("<=") } | Select-Object -ExpandProperty InputObject
                $onlyInConfig = $comparisonResult | Where-Object { $_.SideIndicator -eq [regex]::Escape("=>") } | Select-Object -ExpandProperty InputObject

                foreach ($content in $equalContents) {
                    $result += "" | Select-Object @{N = "Statement in Template"; E = { $content } }, @{N = "Statement in Config"; E = { $content } }, @{N = "Is Mached?"; E = { "Yes" } }
                }

                # Create a value substitured statement list from master file
                $masterMap = @()
                $excludedInMasterMap = @()
                foreach ($line in $master) {
                    if ($($line | Select-Object -ExpandProperty $filename) -eq "") {
                        $excludedInMasterMap += "" | Select-Object @{N = "Statement"; E = { $line.Statement } }, @{N = "MappedStatement"; E = { $line.Statement } }
                    }
                    else {
                        $masterMap += "" | Select-Object @{N = "Statement"; E = { $line.Statement } }, @{N = "MappedStatement"; E = {
                                $line.Statement -replace [regex]::Escape($line.Variable), $($line | Select-Object -ExpandProperty $filename) }
                        }
                    }
                }

                $onlyInConfigCleaned = ($onlyInConfig -replace [regex]::Escape("'"), "") -replace [regex]::Escape('"'), ""
            
                # Compare remaining statements in config with map from master
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
}
elseif ($processChice -eq "2") {
    Write-Host "Config file creation process:" -BackgroundColor Yellow -ForegroundColor Black
    $dirPath = Read-Host "Enter the path of the directory"

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

    if ($proceed) {
        $master = Import-Csv $masterFilePath
        $templateContent = Get-Content -LiteralPath $templatePath
        $devicesInMaster = $master | Get-member -MemberType 'NoteProperty' | Where-Object { $_.Name -ne "Statement" -and $_.Name -ne "Variable" } | Select-Object -ExpandProperty 'Name'

        $devices = $null
        $deviceList = Read-Host "Enter the name of devices, separated by comma (Enter all for all devices)"
        if ($deviceList -ne "all") {
            $devices = $($deviceList -split ",").Trim()
        }
        else {
            $devices = $devicesInMaster
        }

        # Start creating configuration files
        foreach ($device in $devices) {
            Write-Host "Creating configuration for $($device) ..."

            if ($devicesInMaster -contains $device) {
                $masterForThisDevice = $master
                $configForThisDevice = $templateContent
                $configPath = Join-Path -Path $reportDirPath -ChildPath $("Config_" + $device + ".txt")

                foreach ($line in $masterForThisDevice) {
                    $statement = ""
                    $variable = ""
                    $variableValue = ""
                    $fullCmd = ""
                    $statement = $($line | Select-Object -ExpandProperty Statement).Trim()
                    $variable = $($line | Select-Object -ExpandProperty Variable).Trim()
                    $variableValue = $($line | Select-Object -ExpandProperty $device).Trim()

                    # Check if there is value for a variable for a device
                    if ($variableValue -eq "") {
                        # If No, skip
                        if ($configForThisDevice -contains $statement) {
                            $configForThisDevice = $configForThisDevice -replace [regex]::Escape($statement), ""
                            $configForThisDevice = $configForThisDevice | Where-Object { $_ }
                        }
                    }
                    else {
                        # If Yes, add the substitured statement
                        $fullCmd = $statement -replace [regex]::Escape($variable), $variableValue

                        if ($configForThisDevice -contains $statement) {
                            $configForThisDevice = $configForThisDevice -replace [regex]::Escape($statement), $fullCmd
                        }
                    }
                    
                }

                try {
                    $configForThisDevice | Out-File -LiteralPath $configPath -Encoding Unicode -ErrorAction Stop
                    Write-Host "`tDone.`t Config File: $($configPath)" -ForegroundColor Green
                }
                catch {
                    Write-Host "\tFailed to save config!" -ForegroundColor Red
                }

            }
            else {
                Write-Host "`tERROR: Master file does not contains $($device)!" -ForegroundColor Red
            }
            
        }
    }
    
}
else {
    Write-Host "Wrong process choice!" -ForegroundColor Red
}


# To keep the prompet open
Read-Host "Press 'ENTER' to exit."
