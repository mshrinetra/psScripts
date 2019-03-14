## Scan two paths for file differences

Thsis script checks the difeerence between files at two locations recursively and exports the list of files and folders that do not exists at either of the locations or have any differences. It uses the robocopy for fast and robust scanning.

### Input

#### Input File Path

When prompted for path of input CSV File, that contains source and destination paths under columns titled "Source" and "Destination".

* It is advisable to save CSV file in Unicode or UTF-8 encoding format rather than ASCII
* Share paths value should start with double back slashes (\\)

#### Report Directory Path

When prompted for path of report directory, enter the path of directory where results need to be saved.

* For current directory just input a dot (.)
* Do not enter backslash at the end of path


### Output

One index (CSV) file containing the path of report for each path and report files itself in a subdirectory named Validation report in report directory

### Process

* Run the script with powershell
* When prompted for InputFile, give the path of input file and answer other queries.

### EXAMPLE

   PS C:\\> .\Validate-Differences.ps1
   Please enter the path of Input map file: map.csv
   Enter the path of directory where the result will be saved: .
   Creating new subdirectory in report directory to keep all the reports


      Directory: C:\\


   Mode                LastWriteTime     Length Name
   ----                -------------     ------ ----
   d----         3/13/2019   4:42 PM            ValidationReports_2
   Reports for this scan will be saved in: .\\ValidationReports_2
   Validation started at 16:42:28 13-Mar-2019
   ========================================================================
   ------------------------------------------------------------------------
   Validating 1 of 1 for
   SOURCE: C:\\Users\\testuser\\Desktop\\Source
   DESTINATION: C:\\Users\\testuser\\Desktop\\Destination

   Log File : C:\\ValidationReports_2\\Diffs1.txt
   ------------------------------------------------------------------------
   ========================================================================
   Validation Completed!!!
   ===SUMMARY======================================================
   Sart Time:       16:42:28 13-Mar-2019
   End Time:        16:42:28 13-Mar-2019
   Paths Validated: 1
   Total Time:      0 Days, 0 Hours, 0 Minutes and 0.251 Seconds
   ================================================================


### NOTES
Version: 1.0

Author: Manvendra Shrinetra

### LINK

https://github.com/mshrinetra/psScripts
