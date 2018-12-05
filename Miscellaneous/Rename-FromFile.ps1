param(
    # Path of the directory in which files have to be renamed
    [Parameter(Mandatory = $true)]
    [string]
    $DirectoryPath,
    # Path of the file that contains the the new name for files
    [Parameter(Mandatory = $true)]
    [string]
    $NameFile,
    # Initial seed number that will be prepended to new file names
    [Parameter(Mandatory = $true)]
    [int]
    $SeedNumber
)

if ((Test-Path -LiteralPath $DirectoryPath) -and (Test-Path -LiteralPath $NameFile)) {
    $files = Get-ChildItem -LiteralPath $DirectoryPath | Select-Object Name, FullName, Extension | Sort-Object Name
    $newNames = Get-Content -LiteralPath $NameFile
    if (($files | Measure-Object | Select-Object -ExpandProperty Count) -eq ($newNames | Measure-Object | Select-Object -ExpandProperty Count)) {
        $index = 0
        foreach ($file in $files) {
            $newName = $null
            $newNameText = $newNames[$index]
            $newNameText = $newNameText -replace [regex]::Escape("("), ""
            $newNameText = $newNameText -replace [regex]::Escape(")"), ""
            $newNameText = $newNameText -replace [regex]::Escape(";"), ""
            $newNameText = $newNameText -replace [regex]::Escape(","), ""
            $newNameText = $newNameText -replace [regex]::Escape("'"), ""
            $newNameText = $newNameText -replace [regex]::Escape(":"), ""
            $newNameText = $newNameText -replace [regex]::Escape("?"), ""
            $newNameText = $newNameText -replace [regex]::Escape("."), ""
            $newNameText = $newNameText -replace [regex]::Escape("-"), ""
            $newNameText = $newNameText -replace [regex]::Escape("!"), ""
            $newNameText = $newNameText -replace [regex]::Escape("+"), ""
            # $newNameText = $newNameText -replace [regex]::Escape(""), ""
            # $newNameText = $newNameText -replace [regex]::Escape(""), ""
            # $newNameText = $newNameText -replace [regex]::Escape(""), ""
            # $newNameText = $newNameText -replace [regex]::Escape(""), ""
            if ($SeedNumber) {
                $SeedNumber = $SeedNumber + 1
                $newName = $SeedNumber.ToString() + " " + $newNameText + ($file | Select-Object -ExpandProperty Extension)
            }
            else {
                $newName = $newNameText + ($file | Select-Object -ExpandProperty Extension)
            }
            Write-Host "Remaming $($file.Name) `tto`t $newName"
            try {
                Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
                Write-Host "Success!" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed" -ForegroundColor Red 
            }

            $index++
        }
    }
    else {
        Write-Host "Number of files and names in NameFile mismatch" -BackgroundColor Red
    }
}
else {
    Write-Host "Wrong Path" -BackgroundColor Red
}
Read-Host "Press Enter to exit"