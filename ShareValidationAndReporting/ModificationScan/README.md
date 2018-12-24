## Scan the share for Modification

This script scans through the given share and directory paths to count number and calculates percentage by number and by size of the files that got modified in given number of days.

### Input

#### Input File

Input should be a CSV Text file containing paths of shares or directories

* It is advisable to save Text file in Unicode or UTF-8 encoding format rather than ASCII
* FilerPath value should start with double back slashes (\\) and column header i.e. "FilerPath" should be one word

#### Other Inputs

* Type of scan: If you want to scan the path given in input file or its immediate child containers
* Number of days: The number of days for which modified files has to be counted
* Type of process: If you want to only count and calculate modified files or do you also want one modified file path with last modified time or both
* Start Index: From which path do you want to scan, comes handy it you restart the script for any reason


### Output

Output of the script would be one or two CSV (Comma Separated Value) file(s).

* "ModifiedCountReport.csv" file would containd the modified file counts and percentages.
* "OneModifiedFileReport.csv" file would contain full path of one modified file and its modification time
* Log file would contain raw output of robocopy

### Process

* Run the script with powershell
* When prompted for InputFile, give the path of input file and answer other queries.

### EXAMPLE
PS E:\> .\CountAndList-ModifiedFile.ps1
Enter the path of Input Text file: input.txt
Please answer 'g' to scan given paths
's' to scan subdirectories of given path
Your answer: g
Enter the number of days to scan for: 90
Please select processes
1. Count only
2. List one file only
3. Count and List one file
Enter your choise (Serial Number): 3
If you are restarting the process, you can give an index to start from rather than from the begining. Give 0 to start from begining.
Enter the start Index (0 based index i.e. One less than Serial No): 0
Scanning started at 08:43:27 24-Dec-2018
Count Report: ModifiedCountReport.csv
List one Report: OneModifiedFileReport.csv
Log File: CountAndListLog.log
Scanning for 1 in 854 ...
PATH: \\site.dom.com\data
....
....
....
Scanning ompleted !!!
 ========================================================================
===SUMMARY======================================================
Sart Time:       11:18:28 23-Dec-2018
End Time:        13:49:55 23-Dec-2018
Paths Counted:   854
Total Time:      0 Days, 2 Hours, 31 Minutes and 26.538 Seconds
 ================================================================
### NOTES
Version: 1.0
Author: Manvendra Shrinetra
### LINK
https://github.com/mshrinetra/psScripts
#>