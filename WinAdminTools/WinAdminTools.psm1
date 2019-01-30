function Get-PhysicalPathFromDfsPath {
    [CmdletBinding()]
    param (
        # DFS Path
        [Parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "DfsPath")]
        [string]
        $DFSPath,
        # Input text file path
        [Parameter(ParameterSetName = "InputFile")]
        [string]
        $InputFile
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -eq "InputFile") {
            if ((Test-Path $InputFile) -and ((Get-Item $InputFile | Select-Object -ExpandProperty PSIsContainer) -eq $false)) {
                $result = @()
            }
            else {
                $FileNotFoundError = [string]"Input file not found"
                Throw $FileNotFoundError
            }
        }
    }
    
    process {
    }
    
    end {
    }
}