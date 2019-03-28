<#
.SYNOPSIS
Create new Share from CSV input
.DESCRIPTION
This script creates new share, by taking input from CSV file
.INPUTS
Path of Input CSV File containing required fields FolderPath and ShareName and optional fields Description, FullAccess, ChangeAccess and ReadAccess
.OUTPUTS
Result CSV file in working directory named ShareCreationResult.csv
.EXAMPLE
PS E:\SANDBOX\psScripts\ShareCreation> .\Create-NewShare.ps1
Path of the input file: inp.csv
Do you want to create folder if it does not already exists? (Yes/No): No
Creating share 1 : Test
Success!!
Result is saved in ShareCreationResult_1.csv in current folder.
.NOTES
Version: 1.0
Author: Manvendra Shrinetra
.LINK
https://github.com/mshrinetra/psScripts
#>
#requires -version 2

$inputFile = Read-Host "Path of the input file"
$createFolderIfNotExists = Read-Host "Do you want to create folder if it does not already exists? (Yes/No)"
if ($createFolderIfNotExists -eq "Yes") {
    $createFolderIfNotExists = $true
}
else {
    $createFolderIfNotExists = $false
}

if (Test-Path $inputFile.Trim() -PathType Leaf) {
    $csv = $null
    try {
        $csv = Import-Csv $inputFile.Trim() -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: File could not be read!" -ForegroundColor Red
    }

    if ($csv) {
        $result = @()
        $fields = $csv | Get-member -MemberType 'NoteProperty' -ErrorAction Stop | Select-Object -ExpandProperty 'Name' -ErrorAction Stop
        $i = 0
        foreach ($line in $csv) {
            $i++
            $resultLine = $null
            $status = "Fail"
            $statusMsg = ""
            $givenArgs = @{}
            try {
                write-host "Creating share $i : $($line.ShareName)" -ForegroundColor Yellow
                if (!(Test-Path $line.FolderPath.Trim())) {
                    if ($createFolderIfNotExists) {
                        New-Item -Path $line.FolderPath.Trim() -ItemType Directory -Force -ErrorAction Stop | Out-Null
                        Write-Host "`t Folder $($line.FolderPath.Trim())" Created
                    }
                    else {
                        throw "Folder path does not exists"
                    }
                }

                if ($fields -contains "Description") {
                    if (!([string]::IsNullOrEmpty($line.Description))) {
                        $givenArgs.Add("Description", $line.Description.Trim())
                    }
                }

                if ($fields -contains "FullAccess") {
                    if (!([string]::IsNullOrEmpty($line.FullAccess))) {
                        $givenArgs.Add("FullAccess", $line.FullAccess.Trim())
                    }
                }

                if ($fields -contains "ChangeAccess") {
                    if (!([string]::IsNullOrEmpty($line.ChangeAccess))) {
                        $givenArgs.Add("ChangeAccess", $line.ChangeAccess.Trim())
                    }
                }

                if ($fields -contains "ReadAccess") {
                    if (!([string]::IsNullOrEmpty($line.ReadAccess))) {
                        $givenArgs.Add("ReadAccess", $line.ReadAccess.Trim())
                    }
                }

                if (!(Get-SmbShare -Name $($line.ShareName.Trim()) -ErrorAction SilentlyContinue)) {
                    New-SmbShare –Name $($line.ShareName.Trim()) –Path $($line.FolderPath.Trim()) @givenArgs
                }
                else {
                    throw "The share already exists"
                }

                $status = "Success"
                Write-Host "Success!!" -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
                $statusMsg = $($_.Exception.Message)
            }
            $resultLine = $line | Select-Object *, @{N = "Status"; E = {$status}}, @{N = "Message"; E = {$statusMsg}}
            $result += $resultLine
            try {
                $resultFile = "ShareCreationResult.csv"
                $i = 0
                while (Test-Path $resultFile) {
                    $i++
                    $resultFile = "ShareCreationResult_$($i).csv"
                }

                $result | Export-Csv $resultFile -Encoding UTF8 -NoTypeInformation -ErrorAction Stop
                Write-Host "Result is saved in $($resultFile) in current folder." -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR: Failed to save the reult" -ForegroundColor Red
            }
        }
    }
}
else {
    Write-Host "Sorry given input file not found!" -ForegroundColor Red
}

Start-Sleep -Seconds 5