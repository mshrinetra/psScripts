#requires -version 2
<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER <>
    
.INPUTS
    Path of Input File
.OUTPUTS
    Result file at
.NOTES
    Version: 1.0
    Author: Manvendra Shrinetra

.LINK
    https://github.com/mshrinetra/psScripts
.EXAMPLE
    
#>

#----------------------------[Initialisations]----------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#-----------------------------[Declarations]------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "<script_name>.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#---------------------------[Functions]-------------------------

Function ValidateCsv {
    param(
        # List of Headers
        [Parameter(Mandatory = $true)]
        [string[]]
        $HeaderList,
        # Path of the file
        [Parameter(Mandatory = $true)]
        [string]
        $CsvPath
    )
}

<#
Function <FunctionName>{
    Param()
    
    Begin{
        Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
    }
    
    Process{
        Try{
            <code goes here>
        }
        
        Catch{
            Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
            Break
        }
    }
    
    End{
        If($?){
            Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
            Log-Write -LogPath $sLogFile -LineValue " "
        }
    }
}
#>

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile