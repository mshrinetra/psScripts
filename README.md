psScripts
===

This is collection of some of clean and organized powershell scripts which I had written for various administrative tasks. Scripts will be added to this collection as and when either I revisit my script and clean it or I write new script.

These scripts are mostly Non-GUI scripts which take file input and file output. Generally common conventions have been followed for all the scripts, though there might be some differences as per the requirement. The common features are described below.

## Common Input File Formats

### CSV (Comma Separated Value) File

When there is more than one value is required for itirative process then the input should be a CSV (Comma Separated Value) file.

* It is advisable to save CSV file in Unicode or UTF-8 encoding format rather than ASCII
* Field delimiter should be comma (,) and Text delimiter should be double quotes (") for CSV files
* Headers for each column should be as mentioned in the document of script, without any leading, trailing or in between (If not mentioned in the document) spaces
* Input file name should be as mentioned in the document or script with proper (.csv) extension.

### Text File

When ther is only one value required for itirative process then the input should be a Text file.

* It is advisable to save Text file in Unicode or UTF-8 encoding format rather than ASCII
* Headers should not be any header in text input file, as all rows will be treated as separate values by the script, including first row.
* Input file name should be as mentioned in the document or script with proper (.txt) extension.

## Common Output File Formats

### CSV (Comma Separated Value) File

When script generates report for more than one values for a itirative process then the result is saved in CSV file format.

* Most output files will be encoded in Unicode or UTF-8 encoding
* The data types of all the columns would be generally described in the document of the script
* Output file would be exported to directory in which script runs unless mentioned in the document otherwise.

### Text File

When script generates report for one values for a itirative process then the result is saved in Text file format.

* Most output files will be encoded in Unicode or UTF-8 encoding
* Text files would not mention data type in the file, it will be mentioned in the document or on the console at the end of script execution
* Output file would be exported to directory in which script runs unless mentioned in the document otherwise.

## Console Input and Output

Script would take console Input for non itirative tasks or file path of the Input file. Whereas console output would be produced as per script requirements.

While giving file or UNC paths as input, always

* Prifer to give absolute full path
* If giving relative path, give the path in relation to the directory in which script is running
* Give the full file name with extension

### NOTES

Author: Manvendra Shrinetra

### LINK

https://github.com/mshrinetra/psScripts