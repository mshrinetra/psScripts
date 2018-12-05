## Get Share List to Scan

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