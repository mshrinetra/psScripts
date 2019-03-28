## Create new share

This script creates new share, by taking input from CSV file

### Input

#### Input File

Path of Input CSV File containing required fields FolderPath and ShareName and optional fields Description, FullAccess, ChangeAccess and ReadAccess

* It is advisable to save Text file in Unicode or UTF-8 encoding format rather than ASCII
* FilerPath value should start with double back slashes `\\` and column header i.e. "FilerPath" should be one word

##### Example

| FolderPath | ShareName | Description | FullAccess | ChangeAccess | ReadAccess |
----------|---------|-----------|----------|------------|----------|
| E:\\Test | Test | A Test Share | Administrator |  |  |

#### Other Inputs

* Do you want to create folder if it does not already exists? (Yes/No)

Reply with full word "Yes" or "No"


### Output

Result CSV file in working directory named ShareCreationResult.csv

### Process

* Login to the computer on which shares have to be created
* Run the script with powershell
* When prompted for InputFile, give the path of input file and answer other queries.

### EXAMPLE

```
    PS E:\SANDBOX\psScripts\ShareCreation> .\Create-NewShare.ps1
    Path of the input file: inp.csv
    Do you want to create folder if it does not already exists? (Yes/No): No
    Creating share 1 : Test
    Success!!
    Result is saved in ShareCreationResult_1.csv in current folder.
```

### NOTES

Version: 1.0
Author: Manvendra Shrinetra

### LINK

https://github.com/mshrinetra/psScripts
