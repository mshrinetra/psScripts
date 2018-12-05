<#
.NOTES
    Author: Manvendra Shrinetra
.LINK
    http://github.com/mshrinetra
#>

param(
    # Path to the directory where files have to be put into a subfolder
    [Parameter(Mandatory=$true)]
    [string]
    $DirectoryPath,
    # Extention of the files which has to be put into subdirectory
    [Parameter(Mandatory=$true)]
    [string]
    $Extension,
    # Name of the subdirectory
    [Parameter(Mandatory=$true)]
    [string]
    $SubdirectoryName
)

if((Test-Path -LiteralPath $DirectoryPath) -and (!([System.IO.Path]::HasExtension($DirectoryPath)))){
    if($Extension[0] -ne '.'){
        $Extension = '.' + $Extension
    }
    $files = Get-ChildItem -LiteralPath $DirectoryPath | Where-Object {$_.Name -like "*$Extension"} | Select-Object Name, FullName
    $count = $files | Measure-Object | Select-Object -ExpandProperty Count
    if($count -gt 0){
        Write-Host "$count files found" -ForegroundColor Green
        New-Item -LiteralPath $DirectoryPath -Name $SubdirectoryName -ItemType "Directory" -Force
        $SubdirectoryPath = $DirectoryPath + '\' + $SubdirectoryName + '\'
        Write-Host "Subdirectory $SubdirectoryName created" -ForegroundColor Green
        $i = 0
        foreach ($file in $files) {
            $i++
            Write-Host "Moving $i of $count $($file.Name)"
            try{
                Move-Item -LiteralPath $DirectoryPath -Include "*$Extension" -Destination $SubdirectoryName -Force
                Write-Host "Success!" -ForegroundColor Green
            }catch{
                Write-Host "Filed!!!" -ForegroundColor Red
            }
        }
    }
    else{
        Write-Host "No file with given extension found in the directory" -ForegroundColor Red
    }
}
else{
    Write-Host "Given directory not found" -ForegroundColor Red
}