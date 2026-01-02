# mergeFolders
## What will this do?
This script will compare two directories. It will traverse the file structure of both the directories. Both the compared directories will remain unchanged. Then, it will output a combined directory that is called CombinedDir by default.

It will:
- Maintain the current file structure of the two directories.
- If a file/folder is present in either directory and it is NOT present in the other, it will include that file/folder in CombinedDir.
- If a file by the same name is present in both old and new directories, it will copy the file that was most recently modified to the CombinedDir.
- Create a logfile described all actions taken to create CombinedDir. That logile will be generated in CombinedDir and will be called "MergeLog.txt".

## Usage:
1. Download the file MergeFolders.ps1 (or this entire repo).
2. Unblock the script (if needed): Windows sometimes blocks scripts downloaded or created from the web. Right-click the file, select Properties, and check the Unblock box at the bottom, then click OK.
3. Run it from PowerShell: Open PowerShell, navigate to the folder where you saved it, and run it using this syntax:
```bash
.\Merge-Folders.ps1 -OldDir "C:\OldFiles" -NewDir "C:\NewFiles"
```