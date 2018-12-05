## Get Share List to Scan

This script exports the list of paths that should be scanned for various share data validation and reporting tasks

### Input

Input should be a CSV (Comma Separated Value) file, with 3 columns i.e. Site, Filer and FilerPath

* It is advisable to save CSV file in Unicode or UTF-8 encoding format rather than ASCII
* Field delimiter should be comma (,) and Text delimiter should be double quotes (") for CSV files
* Site and Filer values will be as it is exported to out put, which can be used later for sorting and filter.
* FilerPath value should start with double back slashes (\\) and column header i.e. "FilerPath" should be one word

Below is a sample Input file

| Site | Filer | FilerPath |
| ------ | ------ | ------ |
| London | LON001 | \\LON001.mydomain.net |
| London | LON002 | \\LON002.mydomain.net |
| Mumbai | MUM003 | \\MUM003.mydomain.net |
| Mumbai | MUM004 | \\MUM004.mydomain.net |

### Output

Output of the script would be a CSV (Comma Separated Value) file, with 5 columns i.e. Site,Filer,Root Share,Root Share Path,Sub Share Path

* The paths under the column "Sub Share Path" should only be used for validation and reporting tasks
* Output CSV encoding is Unicode
* Output is exported to the directory in which Script runs

Below is a sample output file

| Site | Filer | Root Share | Root Share Path | Sub Share Path |
| ------ | ------ | ------ | ------ | ------ |
| Siegen | SIE001 | ADMIN$ | \\localhost\ADMIN$ | \\localhost\ADMIN$ |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Fake |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Intel |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\MyExc |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\PerfLogs |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Program Files |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Program Files (x86) |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Python |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\SWSetup |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Users |
| Siegen | SIE001 | C$ | \\localhost\C$ | \\localhost\C$\Windows |
| Siegen | SIE001 | D$ | \\localhost\D$ | \\localhost\D$ |
| Siegen | SIE001 | E$ | \\localhost\E$ | \\localhost\E$ |
| Siegen | SIE001 | F$ | \\localhost\F$ | \\localhost\F$ |
| Siegen | SIE001 | IPC$ | NOT FOUND | -- |
| Siegen | SIE001 | Shared | \\localhost\Shared | \\localhost\Shared |

### Process

* Run the script with powershell
* When prompted for InputFile, give the path of CSV file (With extension)

### Working of script

* Get all the shares for all the filers on all the filer
* Check the contnet of the shares
* If share contains the directories, list full path of these directories under "Sub share path"
* If share does not contains any directory list the share under "Sub share path"