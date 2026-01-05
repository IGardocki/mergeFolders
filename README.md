# mergeFolders
## What will this do?
This script will compare two directories. It will traverse the file structure of both the directories. Both the compared directories will remain unchanged. Then, it will output a combined directory that is called CombinedDir by default.

It will:
- Maintain the current file structure of the two directories.
- If a file/folder is present in either directory and it is NOT present in the other, it will include that file/folder in CombinedDir.
- If a file by the same name is present in both old and new directories, it will copy the file that was most recently modified to the CombinedDir.
- Create a logfile describing all actions taken to create CombinedDir. That logile will be generated in CombinedDir and will be called "MergeLog.txt".

## Usage:
1. Either:
  - Create a new folder and download both of the files in this repo into that folder OR
  - Pull this repo
2. Click the CLICK-THIS.bat file.
3. Drag and drop your OLD folder. Press enter.
4. Drag and drop your NEW folder. Press enter.
5. Drag and drop the parent directory where you want your combined directory to be created (so the folder where you want your combined directory to be created). Press enter.
6. Type the name you want for your combined directory, then press enter. Or, press enter for the default name (CombinedDir). Press enter.
7. You will see terminal output as the program works. When it is completed, you will see a folder with the name you typed in step 6 appear in the folder you dragged into the terminal in step 5. That will be your combined directory.